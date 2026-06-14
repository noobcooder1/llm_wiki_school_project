# Work Breakdown Structure

## 1. 기획 및 설계
- 프로젝트 비전, 핵심 사용자 흐름, 보안 요구사항 정리
- 로컬 우선, BYOK, 마크다운, Flutter ADR 작성
- GitHub Pages 발표자료와 초기 WBS 구성

## 2. 앱 기반 및 로컬 데이터 구조
- Flutter 앱 골격 구현
- 라이브러리, AI 채팅, 내보내기, 설정 화면 구성
- 한국어 기본 언어와 영어/일본어 다국어 구조 적용
- Project, Conversation, Message 모델과 로컬 스냅샷 저장 구조 구현

## 3. AI 채팅 및 Provider 연동
- Gemini, GPT/OpenAI, Claude, Grok Provider Client 구현
- Provider별 모델 fallback 및 API 오류 저장 흐름 구현
- Provider별 API 키 저장, 마스킹, 삭제, 활성 키 선택 구현
- Legacy OpenAI 키 마이그레이션 처리

## 4. 지식 라이브러리 및 관리 기능
- 프롬프트와 AI 응답을 Conversation 단위로 저장
- 최근 채팅 Drawer와 프로젝트 필터 구현
- 자동 태그, 수동 태그, 제목/본문/태그 검색 구현
- 코드 스니펫 추출 구현
- 프로젝트 생성, 이름 변경, 삭제와 대화 이동, 복원, 휴지통 구현

## 5. 내보내기, 보안 및 발표 산출물
- 프로젝트 범위 선택형 Markdown Export 구현
- Codex to Obsidian Sync 스크립트와 문서 작성
- 민감정보 마스킹, 암호화 저장 토글, 앱 잠금/E2EE/SQLCipher 경계 정리
- 30초 데모 영상 제작
- 구현 기능 상세 발표자료와 4분 30초 발표 대본 업데이트

## 6. 테스트 및 최종 발표 준비
- 위젯 테스트, 정적 분석, APK 빌드 확인
- Android 및 GitHub Pages 화면 점검
- 최종 발표 리허설과 제출 준비
