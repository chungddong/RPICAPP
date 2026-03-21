# 딸깍 런처 실장비 테스트 가이드 (Raspberry Pi Zero 2W)

이 문서는 `ttl` 런처를 실제 장비에서 검증하는 절차를 정리합니다.

---

## 0. 테스트 목적

- USB 연결만으로 Pi Zero 2W 감지
- rpiboot로 RAM 부팅
- SD카드에 OS 이미지 기록
- 첫 부팅 자동 설치(firstboot) 완료 여부 확인

---

## 1. 준비물

- Raspberry Pi Zero 2W 보드 1대
- **빈 SD카드 1장 (반드시 보드에 삽입)**
- 데이터 전송 가능한 USB 케이블 1개
- Windows PC (런처 실행)
- 인터넷 연결 (firstboot에서 git clone/패키지 설치)

> 중요: Pi Zero 2W는 테스트 시 **SD카드를 꽂아둔 상태**여야 합니다.
> 런처는 보드 자체가 아니라, 보드에 삽입된 SD카드에 OS를 기록합니다.

---

## 2. 프로젝트 파일 준비

프로젝트 루트 기준으로 아래 3개 파일을 배치합니다.

- `launcher/assets/os/ttlak-os.img`
- `launcher/assets/rpiboot/rpiboot.exe`
- `launcher/assets/tools/rpi-imager-cli.cmd` (또는 `.exe`)

확인 명령 (PowerShell):

```powershell
Test-Path .\launcher\assets\os\ttlak-os.img
Test-Path .\launcher\assets\rpiboot\rpiboot.exe
Test-Path .\launcher\assets\tools\rpi-imager-cli.cmd
```

3개 모두 `True`여야 합니다.

---

## 3. 사전 안전 체크

- 외장 SSD/USB 메모리 등 **불필요한 저장장치 분리**
- 테스트는 처음에 반드시 **장비 1대만 연결**
- 관리자 권한 PowerShell 권장

---

## 4. 런처 설치

프로젝트 루트에서:

```powershell
py -m pip install -e launcher
```

검증:

```powershell
ttl -h
```

---

## 5. Dry-run 확인 (하드웨어 없이)

```powershell
ttl --project-root . run --ref main --dry-run
```

기대 결과:
- `idle -> ... -> completed` 상태 전이가 출력됨

---

## 6. 실장비 연결 방법 (Zero 2W)

1. SD카드를 Zero 2W에 삽입
2. BOOT 모드로 연결
   - 일반적으로 `BOOTSEL`(또는 저장장치 모드 진입 조건) 상태에서 USB 연결
   - 하드웨어 리비전에 따라 진입 방식이 다를 수 있으므로 팀 표준 절차 우선
3. Windows 장치 관리자에서 `BCM2835 Boot` 계열로 인식되는지 확인

---

## 7. 단일 실장비 테스트 실행

```powershell
ttl --project-root . run --ref main
```

정상 시 기대 흐름:
1. 장치 감지
2. RAM boot(rpiboot)
3. Mass Storage 노출
4. OS 이미지 플래시
5. provisioning/verify/register 단계
6. `completed`

---

## 8. 성공 판정 기준

아래 모두 만족하면 1회 성공:

- CLI 상태가 `completed`로 종료
- Pi가 SD로 정상 부팅
- firstboot 완료 플래그 확인

Pi에서 확인:

```bash
sudo test -f /var/lib/ttlak/success.flag && echo OK
sudo tail -n 100 /var/log/ttlak/firstboot.log
```

---

## 9. 실패 시 점검 순서

### 9-1. 감지 실패 (`E001`)
- 케이블이 충전 전용인지 확인
- USB 포트 변경
- 장치 관리자에서 `BCM2835 Boot` 존재 확인

### 9-2. rpiboot 실패 (`E002`)
- `rpiboot.exe` 경로/권한 확인
- 백신/보안SW 차단 여부 확인

### 9-3. 저장장치 노출 실패 (`E003`)
- SD카드 삽입 여부 재확인
- SD카드 불량/접점 불량 점검

### 9-4. 플래시 실패 (`E004`)
- `rpi-imager-cli.cmd/.exe` 실행 가능 여부 단독 확인
- 잘못된 디스크 선택 위험 방지 위해 외부 저장장치 분리

### 9-5. firstboot 실패 (`E005`)
- 네트워크 연결 확인
- Pi에서 로그 확인: `/var/log/ttlak/firstboot.log`

---

## 10. 반복 검증 기준 (권장)

- 단일 장비 3회 연속 성공
- 실패 발생 시 원인 수정 후 다시 3회
- 이후 멀티 테스트 진행

멀티 테스트:

```powershell
ttl --project-root . multi --slots 2 --ref main
```

---

## 11. 운영 팁

- `main`은 생산 기준, `develop`은 검증용으로 분리 운영
- 이미지/툴 버전은 배포 전 해시 기록 권장
- 테스트 결과는 `launcher/build/registration.jsonl` 누적 확인

---

## 12. 빠른 체크리스트

- [ ] Zero 2W에 SD 삽입
- [ ] assets 3종 파일 배치 완료
- [ ] `ttl --dry-run` 완료
- [ ] 단일 실장비 1회 성공
- [ ] 단일 실장비 3회 연속 성공
- [ ] 멀티 슬롯 테스트 진입
