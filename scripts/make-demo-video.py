from __future__ import annotations

import math
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FRAME_DIR = ROOT / "build" / "demo_frames"
OUTPUT = ROOT / "docs" / "LLM_Wiki_Demo_30s.mp4"
WIDTH = 1280
HEIGHT = 720
FPS = 15
DURATION = 30
TOTAL_FRAMES = FPS * DURATION

INK = "#18201c"
MUTED = "#65706a"
PAPER = "#f7f5ef"
SURFACE = "#ffffff"
LINE = "#d9ded7"
GREEN = "#176b5d"
MINT = "#d9ebe4"
RUST = "#914b32"
BLUE = "#4f5f8c"
GOLD = "#c99a2e"

FONT_PATH = "/System/Library/Fonts/AppleSDGothicNeo.ttc"


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    # AppleSDGothicNeo.ttc contains multiple faces. The default face keeps
    # Korean text crisp enough for a 720p presentation video.
    return ImageFont.truetype(FONT_PATH, size=size)


F = {
    "hero": font(64),
    "h1": font(44),
    "h2": font(30),
    "body": font(24),
    "small": font(18),
    "tiny": font(15),
    "phone_title": font(26),
    "metric": font(38),
    "button": font(20),
}


def ease(x: float) -> float:
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def scene_progress(t: float, start: float, end: float) -> float:
    return ease((t - start) / (end - start))


def draw_round(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, xy, body: str, fill=INK, f=None, anchor=None):
    draw.text(xy, body, fill=fill, font=f or F["body"], anchor=anchor)


def multiline(draw: ImageDraw.ImageDraw, xy, body: str, fill=MUTED, f=None, width=520, line_gap=10):
    f = f or F["body"]
    words = body.split(" ")
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), candidate, font=f)[2] <= width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    x, y = xy
    line_h = f.size + line_gap
    for i, line in enumerate(lines):
        text(draw, (x, y + i * line_h), line, fill=fill, f=f)


def caption_panel(draw: ImageDraw.ImageDraw, t: float):
    scenes = [
        (0, 5.5, "AI 대화를 지식으로 저장", "프로젝트별로 대화와 태그를 모아 나중에 다시 찾을 수 있게 합니다."),
        (5.5, 10.5, "사용자 API 키로 직접 생성", "API 키는 마스킹되어 보관되고, 사용자가 호출과 비용을 직접 통제합니다."),
        (10.5, 18.5, "질문과 답변을 함께 저장", "한국어 프롬프트를 입력하면 AI 응답까지 하나의 대화 기록으로 남깁니다."),
        (18.5, 24.5, "검색으로 다시 활용", "제목, 본문, 태그를 기준으로 필요한 지식을 빠르게 찾습니다."),
        (24.5, 30.1, "마크다운으로 내보내기", "Obsidian, Git, 문서 도구로 옮겨 장기 지식 자산으로 활용합니다."),
    ]
    for start, end, title, desc in scenes:
        if start <= t < end:
            local = scene_progress(t, start, min(start + 0.8, end))
            y = 118 - int((1 - local) * 18)
            text(draw, (86, y), title, fill=INK, f=F["h1"])
            multiline(draw, (88, y + 76), desc, f=F["body"], width=490)
            break

    # Progress rail.
    x0, y0, w, h = 86, 632, 500, 10
    draw_round(draw, (x0, y0, x0 + w, y0 + h), 5, "#e5e5dc")
    draw_round(draw, (x0, y0, x0 + w * min(t / DURATION, 1), y0 + h), 5, GREEN)
    labels = ["라이브러리", "설정", "캡처", "검색", "내보내기"]
    for i, label in enumerate(labels):
        text(draw, (x0 + i * 104, y0 + 24), label, fill=MUTED, f=F["tiny"])


def phone_shell(draw: ImageDraw.ImageDraw):
    x, y, w, h = 760, 54, 360, 620
    draw_round(draw, (x, y, x + w, y + h), 36, "#202823")
    draw_round(draw, (x + 14, y + 14, x + w - 14, y + h - 14), 26, "#fbfaf6")
    draw_round(draw, (x + 132, y + 28, x + 228, y + 34), 4, "#202823")
    return x + 34, y + 62, w - 68, h - 96


def metric(draw, x, y, value, label):
    draw_round(draw, (x, y, x + 134, y + 86), 8, SURFACE, LINE, 1)
    text(draw, (x + 16, y + 14), value, fill=INK, f=F["metric"])
    text(draw, (x + 16, y + 58), label, fill=MUTED, f=F["small"])


def tag(draw, x, y, label, color="#fbfaf6"):
    draw_round(draw, (x, y, x + len(label) * 10 + 28, y + 30), 8, color, LINE, 1)
    text(draw, (x + 12, y + 6), label, fill=MUTED, f=F["tiny"])
    return x + len(label) * 10 + 38


def tab_bar(draw, px, py, pw, ph, selected):
    labels = [("라이브러리", "▣"), ("캡처", "+"), ("내보내기", "⇧"), ("설정", "⚙")]
    y = py + ph - 64
    draw.rectangle((px - 2, y - 8, px + pw + 2, py + ph + 10), fill="#e8f1ec")
    cell = pw / 4
    for i, (label, icon) in enumerate(labels):
        cx = px + cell * i + cell / 2
        if label == selected:
            draw_round(draw, (cx - 54, y + 2, cx + 54, y + 42), 22, "#c6efe3")
        text(draw, (cx, y + 7), icon, fill=INK if label == selected else MUTED, f=F["button"], anchor="ma")
        text(draw, (cx, y + 40), label, fill=INK if label == selected else MUTED, f=F["tiny"], anchor="ma")


def library_screen(draw, px, py, pw, ph, t, search_query=""):
    text(draw, (px, py), "LLM Wiki", f=F["phone_title"])
    metric(draw, px, py + 50, "3", "프로젝트")
    metric(draw, px + 148, py + 50, "12", "대화")
    metric(draw, px, py + 148, "28", "태그")
    metric(draw, px + 148, py + 148, "7", "코드")
    draw_round(draw, (px, py + 252, px + pw, py + 304), 22, "#e7eee9")
    text(draw, (px + 20, py + 267), "⌕", f=F["h2"], fill=INK)
    text(draw, (px + 58, py + 266), search_query or "제목, 본문, 태그 검색", f=F["small"], fill=MUTED)
    chip_x = px
    for label, color in [("✓ 전체", "#d5efe8"), ("모바일 앱", "#eef6f3"), ("리서치", "#eef6f3")]:
        draw_round(draw, (chip_x, py + 320, chip_x + 88, py + 358), 8, color, "#bfd2cc")
        text(draw, (chip_x + 16, py + 329), label, f=F["tiny"], fill=INK)
        chip_x += 98
    card_y = py + 382
    draw_round(draw, (px, card_y, px + pw, card_y + 116), 8, SURFACE, LINE)
    text(draw, (px + 18, card_y + 18), "모바일 앱", fill=GREEN, f=F["tiny"])
    text(draw, (px + 18, card_y + 44), "API 키 안전 저장 방식", fill=INK, f=F["small"])
    text(draw, (px + 18, card_y + 76), "Secure Storage와 마스킹 정책을 정리한 대화", fill=MUTED, f=F["tiny"])
    tag(draw, px + 18, card_y + 106, "#security")
    tag(draw, px + 112, card_y + 106, "#keychain")
    tab_bar(draw, px, py, pw, ph, "라이브러리")


def settings_screen(draw, px, py, pw, ph, t):
    text(draw, (px, py), "설정", f=F["phone_title"])
    text(draw, (px, py + 48), "보안", f=F["h2"])
    draw_round(draw, (px, py + 96, px + pw, py + 164), 8, SURFACE, LINE)
    text(draw, (px + 18, py + 112), "OpenAI API 키", f=F["small"])
    text(draw, (px + 18, py + 140), "sk-••••••••••••••••••••", f=F["tiny"], fill=MUTED)
    if t > 7.3:
        draw_round(draw, (px + pw - 96, py + 116, px + pw - 18, py + 150), 17, GREEN)
        text(draw, (px + pw - 57, py + 124), "저장됨", f=F["tiny"], fill="#ffffff", anchor="ma")
    for i, label in enumerate(["민감정보 마스킹", "앱 잠금", "로컬 우선 저장"]):
        y = py + 194 + i * 58
        draw_round(draw, (px, y, px + pw, y + 44), 8, SURFACE, LINE)
        text(draw, (px + 18, y + 11), label, f=F["small"])
        draw_round(draw, (px + pw - 66, y + 10, px + pw - 18, y + 34), 12, "#c7eadf" if i != 1 else "#edf0ed")
        if i != 1:
            draw.ellipse((px + pw - 40, y + 12, px + pw - 20, y + 32), fill=GREEN)
    tab_bar(draw, px, py, pw, ph, "설정")


def capture_screen(draw, px, py, pw, ph, t):
    text(draw, (px, py), "AI 대화 캡처", f=F["phone_title"])
    text(draw, (px, py + 42), "프로젝트", f=F["tiny"], fill=MUTED)
    draw_round(draw, (px, py + 66, px + pw, py + 106), 8, SURFACE, LINE)
    text(draw, (px + 16, py + 76), "모바일 앱", f=F["small"])
    text(draw, (px, py + 132), "프롬프트", f=F["tiny"], fill=MUTED)
    draw_round(draw, (px, py + 156, px + pw, py + 314), 8, SURFACE, LINE)
    prompt = "Flutter 앱에서 API 키를 안전하게 저장하는 방법을 정리해줘."
    visible_count = int(len(prompt) * scene_progress(t, 10.8, 14.8))
    multiline(draw, (px + 16, py + 174), prompt[:visible_count], f=F["small"], fill=INK, width=pw - 34, line_gap=8)
    draw_round(draw, (px, py + 334, px + pw, py + 382), 10, GREEN)
    label = "답변 생성 중..." if 15.2 <= t < 16.8 else "질문하고 저장"
    text(draw, (px + pw / 2, py + 346), label, f=F["button"], fill="#ffffff", anchor="ma")
    if t >= 16.8:
        draw_round(draw, (px, py + 406, px + pw, py + 510), 8, SURFACE, LINE)
        text(draw, (px + 16, py + 424), "API 키 안전 저장 방식", f=F["small"])
        text(draw, (px + 16, py + 454), "프롬프트와 AI 응답을 함께 저장했습니다.", f=F["tiny"], fill=MUTED)
        tag(draw, px + 16, py + 482, "#keychain")
        tag(draw, px + 112, py + 482, "#security")
    tab_bar(draw, px, py, pw, ph, "캡처")


def export_screen(draw, px, py, pw, ph):
    text(draw, (px, py), "내보내기", f=F["phone_title"])
    draw_round(draw, (px, py + 58, px + pw, py + 170), 8, SURFACE, LINE)
    text(draw, (px + 18, py + 78), "Markdown Export", f=F["small"])
    text(draw, (px + 18, py + 110), "프로젝트별 대화를 .md 파일로 정리", f=F["tiny"], fill=MUTED)
    draw_round(draw, (px + 18, py + 132, px + 150, py + 158), 8, "#eef6f3", LINE)
    text(draw, (px + 30, py + 137), "Obsidian-ready", f=F["tiny"], fill=GREEN)
    for i, label in enumerate(["제목", "프롬프트", "AI 응답", "태그"]):
        y = py + 212 + i * 52
        draw_round(draw, (px, y, px + pw, y + 38), 8, SURFACE, LINE)
        text(draw, (px + 18, y + 10), label, f=F["small"])
    tab_bar(draw, px, py, pw, ph, "내보내기")


def cursor(draw, t, target):
    x, y = target
    pulse = 1 + 0.12 * math.sin(t * 8)
    r = int(16 * pulse)
    draw.ellipse((x - r, y - r, x + r, y + r), outline=GREEN, width=4)
    draw.ellipse((x - 7, y - 7, x + 7, y + 7), fill="#39d2b6")


def render_frame(i: int):
    t = i / FPS
    img = Image.new("RGB", (WIDTH, HEIGHT), PAPER)
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, WIDTH, HEIGHT), fill=PAPER)
    draw.ellipse((690, 34, 1180, 680), fill="#f1f0ea")
    text(draw, (86, 70), "LLM Wiki Demo", fill=GREEN, f=F["small"])
    caption_panel(draw, t)
    px, py, pw, ph = phone_shell(draw)

    if t < 5.5:
        library_screen(draw, px, py, pw, ph, t)
        cursor(draw, t, (px + 68, py + ph - 48))
    elif t < 10.5:
        settings_screen(draw, px, py, pw, ph, t)
        cursor(draw, t, (px + pw - 58, py + 132))
    elif t < 18.5:
        capture_screen(draw, px, py, pw, ph, t)
        if 14.9 <= t < 16.2:
            cursor(draw, t, (px + pw / 2, py + 360))
    elif t < 24.5:
        q = "API 키"[: int(4 * scene_progress(t, 18.8, 20.4))]
        library_screen(draw, px, py, pw, ph, t, q)
        cursor(draw, t, (px + 96, py + 280))
    else:
        export_screen(draw, px, py, pw, ph)
        cursor(draw, t, (px + pw / 2, py + ph - 48))

    # Closing line fades in during the last seconds.
    if t > 26:
        alpha = scene_progress(t, 26, 28)
        overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.rounded_rectangle((76, 500, 620, 590), radius=18, fill=(255, 255, 255, int(210 * alpha)))
        od.text((106, 526), "AI 대화를 다시 찾고, 연결하고, 오래 남깁니다.", fill=(24, 32, 28, int(255 * alpha)), font=F["body"])
        img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

    return img


def main():
    if FRAME_DIR.exists():
        shutil.rmtree(FRAME_DIR)
    FRAME_DIR.mkdir(parents=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    for i in range(TOTAL_FRAMES):
        render_frame(i).save(FRAME_DIR / f"frame_{i:04d}.png", optimize=True)
        if i % 75 == 0:
            print(f"rendered {i}/{TOTAL_FRAMES}")

    encoder = ROOT / "scripts" / "png_sequence_to_mp4.swift"
    subprocess.run(
        [
            "swift",
            str(encoder),
            str(FRAME_DIR),
            str(OUTPUT),
            str(FPS),
            str(WIDTH),
            str(HEIGHT),
        ],
        check=True,
    )
    print(OUTPUT)


if __name__ == "__main__":
    main()
