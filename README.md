# 개발자 '작업실' 꾸미기 — 개발 워크스테이션 구축

## 1. 프로젝트 개요

리눅스 CLI(터미널), Docker(컨테이너), Git/GitHub를 직접 손으로 세팅하며 "내 컴퓨터에서만 되는" 문제를 줄이고,
재현 가능한 개발 실행 환경을 구성하는 것을 목표로 한다. 터미널로 작업 디렉토리와 권한을 정리하고, Docker를
설치·점검한 뒤 컨테이너를 실행/관리하고, Dockerfile로 웹 서버를 컨테이너화해 포트 매핑·바인드 마운트·볼륨을
직접 검증한다.

## 2. 실행 환경

| 항목 | 값 |
|---|---|
| OS | macOS 15.7.4 (Build 24G517) |
| Shell | /bin/zsh |
| Docker | 28.5.2, build ecc6942 (OrbStack 기반) |
| Docker Compose | v2.40.3 |
| Git | 2.53.0 |

```bash
$ sw_vers
ProductName:    macOS
ProductVersion: 15.7.4
BuildVersion:   24G517

$ echo $SHELL
/bin/zsh

$ git --version
git version 2.53.0

$ docker --version
Docker version 28.5.2, build ecc6942
```

> 서울캠퍼스 sudo 정책 제약으로 Docker Desktop 대신 **OrbStack**을 사용했다. OrbStack 앱을 실행하면 내부적으로
> Docker 엔진이 함께 구동되며, 이후 터미널에서는 `docker` 명령을 동일하게 사용할 수 있다.

## 3. 수행 항목 체크리스트

- [x] 터미널 기본 조작 (pwd/ls -al/mkdir/cd/touch/cat/cp/mv/rm)
- [x] 권한 확인/변경 실습 (파일 1개, 디렉토리 1개)
- [x] Docker 설치 및 점검 (`docker --version`, `docker info`)
- [x] Docker 기본 운영 (`images`, `ps`, `ps -a`, `logs`, `stats`)
- [x] `hello-world` 실행
- [x] `ubuntu` 컨테이너 진입 및 명령 실행
- [x] attach vs exec 차이 관찰
- [x] Dockerfile 기반 커스텀 이미지 (nginx:alpine + 정적 콘텐츠)
- [x] 포트 매핑 브라우저 접속 증거
- [ ] 바인드 마운트 전/후 비교 (진행 예정)
- [ ] Docker 볼륨 영속성 검증 (진행 예정)
- [x] Git 사용자 정보 명시적 설정 + `git config --list` 기록
- [x] VSCode에서 GitHub 로그인 및 저장소 연동
- [x] 트러블슈팅 1건 이상 기록 (2건 목표, 1건 완료)

## 4. 터미널 조작 로그

기본 명령(현재 위치 확인 → 목록 확인(숨김 파일 포함) → 생성/이동 → 파일 내용 확인/생성 → 복사 → 이름변경 → 삭제) 흐름:

```bash
$ pwd
/Users/k.jimin20022503/Desktop

$ ls -al
total 16
drwx------+  5 k.jimin20022503  k.jimin20022503   160  7 29 10:31 .
drwxr-x---+ 20 k.jimin20022503  k.jimin20022503   640  7 29 10:50 ..
-rw-r--r--@  1 k.jimin20022503  k.jimin20022503  6148  7 29 10:31 .DS_Store
-rw-r--r--   1 k.jimin20022503  k.jimin20022503     0  7 29 10:13 .localized
drwxr-xr-x   8 k.jimin20022503  k.jimin20022503   256  7 29 10:31 codyssey_w1

$ mkdir dir1
$ cd dir1
$ touch memo.txt
$ echo "hello" > memo.txt
$ cat memo.txt
hello

$ cp memo.txt memo_cp.txt
$ ls
memo_cp.txt memo.txt

$ mv memo_cp.txt rename.txt
$ ls
memo.txt   rename.txt

$ rm rename.txt
$ ls -al
total 8
drwxr-xr-x  3 k.jimin20022503  k.jimin20022503   96  7 29 10:54 .
drwx------+ 6 k.jimin20022503  k.jimin20022503  192  7 29 10:50 ..
-rw-r--r--  1 k.jimin20022503  k.jimin20022503    6  7 29 10:50 memo.txt
```

전체 터미널 캡처: [docs/images/term_log.png](docs/images/term_log.png)

**절대 경로 vs 상대 경로**: `pwd`가 보여준 `/Users/k.jimin20022503/Desktop/dir1`은 루트(`/`)부터 시작하는
**절대 경로**다. 반면 `cd dir1`이나 `mv memo_cp.txt rename.txt`에서 쓰인 `dir1`, `memo_cp.txt`는 **현재 위치를
기준으로 한 상대 경로**로, 같은 파일이라도 실행 위치가 바뀌면 다른 결과를 가리킬 수 있다.

## 5. 권한 실습 (파일 1개 + 디렉토리 1개, 전/후 비교)

```bash
$ ls -l
total 8
-rw-r--r--  1 k.jimin20022503  k.jimin20022503   6  7 29 10:50 memo.txt
drwxr-xr-x  2 k.jimin20022503  k.jimin20022503  64  7 29 10:57 perm

# --- 변경 전 ---
# memo.txt : -rw-r--r-- (644)
# perm/    : drwxr-xr-x (755)

$ chmod 600 memo.txt
$ ls -l memo.txt
-rw-------  1 k.jimin20022503  k.jimin20022503  6  7 29 10:50 memo.txt

$ chmod 700 perm
$ ls -ld perm
drwx------  2 k.jimin20022503  k.jimin20022503  64  7 29 10:57 perm
# --- 변경 후 ---
# memo.txt : -rw------- (600, 소유자만 읽기/쓰기)
# perm/    : drwx------ (700, 소유자만 읽기/쓰기/실행)
```

전체 캡처: [docs/images/permission.png](docs/images/permission.png)

**r/w/x 및 755·644 해석**: 권한은 소유자(owner)/그룹(group)/기타(other) 3자리로 나뉘고, 각 자리는
r=4, w=2, x=1의 합으로 표현된다. `644`는 `rw-r--r--` — 소유자는 읽기/쓰기(6), 그룹과 기타는 읽기만(4) 가능하다.
`755`는 `rwxr-xr-x` — 소유자는 읽기/쓰기/실행(7), 그룹과 기타는 읽기/실행(5)만 가능하다. 디렉토리의 실행(x)
권한은 "그 디렉토리 안으로 들어갈 수 있는지"를 의미한다.

## 6. Docker 설치 · 점검 · 운영 로그

### 설치/점검

```bash
$ docker --version
Docker version 28.5.2, build ecc6942

$ docker info
Client:
 Version:    28.5.2
 Context:    orbstack
 Debug Mode: false

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 28.5.2
 Storage Driver: overlay2
 Kernel Version: 6.17.8-orbstack-...
 Operating System: OrbStack
 OSType: linux
 Architecture: x86_64
 CPUs: 6
 Total Memory: 15.67GiB
```

전체 캡처: [docs/images/docker_checking.png](docs/images/docker_checking.png)

`docker info`가 데몬 관련 오류 없이 Server 정보를 정상 출력 → OrbStack의 Docker 엔진이 정상 동작 중임을 확인.

### 이미지 다운로드/목록

```bash
$ docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
...
Status: Downloaded newer image for nginx:latest

$ docker images
IMAGE          ID           DISK USAGE  CONTENT SIZE  EXTRA
nginx:latest   5a88c9c45479   240MB       66MB
```

캡처: [docs/images/docker_pull_images.png](docs/images/docker_pull_images.png)

### 컨테이너 실행/중지/목록

```bash
$ docker run -d --name test nginx
54c1fadfed2a665af1aff308b677e341c917ceccc51f865ce8f1bb964f8a6284

$ docker ps
CONTAINER ID   IMAGE   COMMAND                  CREATED         STATUS         PORTS    NAMES
54c1fadfed2a   nginx   "/docker-entrypoint...."  4 seconds ago   Up 4 seconds   80/tcp   test

$ docker stop test
test

$ docker ps -a
CONTAINER ID   IMAGE   COMMAND                  CREATED          STATUS                     NAMES
54c1fadfed2a   nginx   "/docker-entrypoint...."  21 seconds ago   Exited (0) 4 seconds ago   test
```

캡처: [docs/images/docker_run_stop.png](docs/images/docker_run_stop.png)

### 로그 확인 & 리소스 확인

```bash
$ docker start test
test

$ docker logs test
...
2026/07/29 08:11:19 [notice] 1#1: start worker processes
...
2026/07/29 08:11:36 [notice] 1#1: signal 3 (SIGQUIT) received, shutting down
...
2026/07/29 08:12:34 [notice] 1#1: start worker processes
...

$ docker stats --no-stream
CONTAINER ID   NAME   CPU %   MEM USAGE / LIMIT    MEM %   NET I/O        BLOCK I/O     PIDS
54c1fadfed2a   test   0.00%   6.27MiB / 15.69GiB   0.04%   1.13kB / 126B  9.92MB / 0B   7
```

캡처: [docs/images/docker_log_resource.png](docs/images/docker_log_resource.png)

### 정리

```bash
$ docker stop test && docker rm test
test
test

$ docker ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
(없음)
```

캡처: [docs/images/docker_stop.png](docs/images/docker_stop.png)

## 7. 컨테이너 실습 (hello-world / ubuntu / attach vs exec)

### hello-world

```bash
$ docker run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

캡처: [docs/images/docker_hello-world.png](docs/images/docker_hello-world.png)

### ubuntu 진입 및 내부 명령

```bash
$ docker run -it --name ubt ubuntu
root@5e6348c848aa:/# ls
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@5e6348c848aa:/# echo "hello"
hello
```

캡처: [docs/images/docker_ubt.png](docs/images/docker_ubt.png)

### attach vs exec 차이 관찰

메인 프로세스를 `bash`로 두고(`-dit`), `exec` 진입 후 `exit`한 경우와 `attach` 후 `exit`한 경우를 비교했다.

```bash
$ docker run -dit --name ubt2 ubuntu bash
cddca44bc1e5e589148a08a792f7c8ce3de7e674714cafa83940647d85ceb60c

# ① exec 로 진입 → exit
$ docker exec -it ubt2 bash
root@cddca44bc1e5:/# exit
exit

$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED          STATUS          NAMES
cddca44bc1e5   ubuntu    "bash"    45 seconds ago   Up 44 seconds   ubt2
# → exec 로 만든 셸만 종료됨. 컨테이너 본체(PID 1)는 계속 살아있음

# ② attach 로 메인 프로세스에 직접 연결 → exit
$ docker attach ubt2
root@cddca44bc1e5:/# exit
exit

$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED          STATUS                     NAMES
cddca44bc1e5   ubuntu    "bash"    About a minute ago  Exited (0) 3 seconds ago  ubt2
# → attach 는 PID 1(메인 프로세스)에 직접 연결되므로, exit 하면 컨테이너 자체가 종료됨
```

캡처: [docs/images/troubleshooting/docker_attach.png](docs/images/troubleshooting/docker_attach.png)

| 구분 | 연결 대상 | `exit`(또는 종료 시그널) 결과 |
|---|---|---|
| `docker exec -it <c> bash` | 컨테이너 안에 **새로 추가한** 프로세스 | 그 프로세스만 종료, 컨테이너는 계속 실행(Up) |
| `docker attach <c>` | 컨테이너의 **메인 프로세스(PID 1)** | 메인 프로세스 종료 = 컨테이너 종료(Exited) |

이 차이를 발견하게 된 과정(원래는 `sleep 3600`을 메인 프로세스로 두고 `attach` 후 Ctrl+C로 테스트했다가
컨테이너가 죽지 않아 당황했던 경험)은 12번 트러블슈팅 항목에 별도로 정리했다.

## 8. Dockerfile 기반 커스텀 이미지 제작

- **선택한 기존 베이스**: (A) 웹 서버 베이스 이미지 활용 — `nginx:alpine` 공식 이미지
- **커스텀 포인트**

| 적용 내용 | 목적 |
|---|---|
| `COPY app/index.html /usr/share/nginx/html/index.html` | nginx 기본 환영 페이지를 내가 작성한 정적 콘텐츠로 교체 |
| `ENV SERVICE_NAME=web` | 서비스 식별 값을 이미지 코드가 아닌 환경변수로 분리(설정과 코드의 분리) |

`Dockerfile`:

```dockerfile
FROM nginx:alpine

COPY app/index.html /usr/share/nginx/html/index.html

ENV SERVICE_NAME=web
```

`app/index.html` (발췌):

```html
<h1>커스텀 NGINX 페이지</h1>
<p>이 페이지는 Docker 컨테이너에서 실행되는 NGINX 서버의 커스텀 페이지입니다.</p>
```

빌드/실행:

```bash
$ docker build -t my-web:1.0 .
...
#6 [2/2] COPY app/index.html /usr/share/nginx/html/index.html
#7 exporting to image
#7 writing image sha256:623c35ae937632041870c577bcbea1467f7a71af26d8620b7831b61ccc822930 done
#7 naming to docker.io/library/my-web:1.0 done

$ docker images
REPOSITORY   TAG   IMAGE ID       CREATED         SIZE
my-web       1.0   623c35ae9376   8 seconds ago   62.4MB

$ docker run -d --name my-web -p 8080:80 my-web:1.0
89a31357ba27f21ce1f7e9869eb4a1b859f7195ba9e41cc5ba855cbff18f413a

$ docker ps --filter name=my-web
CONTAINER ID   IMAGE        COMMAND                  STATUS                  PORTS                          NAMES
89a31357ba27   my-web:1.0   "/docker-entrypoint..."  Up Less than a second   0.0.0.0:8080->80/tcp           my-web
```

## 9. 포트 매핑 접속 증거

`-p 8080:80`으로 실행한 뒤 `curl`과 브라우저로 각각 접속을 확인했다.

```bash
$ curl http://localhost:8080
<!DOCTYPE html>
<html lang="ko">
...
	<h1>커스텀 NGINX 페이지</h1>
	<p>이 페이지는 Docker 컨테이너에서 실행되는 NGINX 서버의 커스텀 페이지입니다.</p>
	<p>포트 매핑 증거: 8080:80</p>
</body>
</html>
```

![포트 매핑 접속 성공](docs/images/port-mapping.png)

## 10. 바인드 마운트 & 볼륨 영속성 검증

> TODO — 아래 절차대로 진행 후 전/후 캡처 첨부 예정

### 10-A. 바인드 마운트 (호스트 변경 → 즉시 반영 확인)

```bash
$ docker run -d --name bind-web -p 8081:80 -v $(pwd)/app:/usr/share/nginx/html nginx:alpine
# 변경 전: http://localhost:8081 접속 캡처
# app/index.html 수정 후
# 변경 후: 새로고침 → 반영 확인 캡처
```

### 10-B. Docker 볼륨 (컨테이너 삭제 후에도 데이터 유지)

```bash
$ docker volume create my-data
$ docker run -it --name vol-test -v my-data:/data ubuntu bash
# echo "지워지지 않는 데이터" > /data/proof.txt && cat /data/proof.txt

$ docker rm -f vol-test

$ docker run -it --name vol-test2 -v my-data:/data ubuntu bash
# cat /data/proof.txt  → 삭제 전과 동일한 내용 확인
```

## 11. Git / GitHub / VSCode 연동

`user.name`, `user.email`, `init.defaultBranch`를 명시적으로 설정했다. 이메일은 개인정보 노출을 피하기 위해
GitHub가 제공하는 noreply 주소(`{GitHub user id}+{username}@users.noreply.github.com`)를 사용했다 —
실제 개인 이메일이 커밋 기록에 남지 않으면서도 GitHub 계정과는 정상적으로 연결된다.

```bash
$ git config --global user.name "강지민"
$ git config --global user.email "225418468+ji-min0@users.noreply.github.com"
$ git config --global init.defaultBranch main

$ git config --list
credential.helper=osxkeychain
user.name=강지민
user.email=225418468+ji-min0@users.noreply.github.com
init.defaultbranch=main
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
core.ignorecase=true
core.precomposeunicode=true
remote.origin.url=https://github.com/ji-min0/codyssey_w1.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main
```

> 참고: 이 설정 이전에 만든 과거 커밋들의 작성자 정보는 호스트네임 기반 자동 설정 값(`강지민
> <k.jimin20022503@...codyssey.kr>`) 그대로 남아있다. 과거 히스토리를 다시 쓰지는 않았고,
> 이 설정 이후의 신규 커밋부터 위 GitHub noreply 이메일로 기록된다.

VSCode에서 GitHub 로그인 후 커밋/푸시가 정상 동작함을 확인:

```
$ git add .
$ git commit -m "init: add initial Dockerfile, README.md, and docker-compose.yml"
[main (root-commit) 738cd81] init: add initial Dockerfile, README.md, and docker-compose.yml
 3 files changed, 0 insertions(+), 0 deletions(-)

$ git push --set-upstream origin main
...
branch 'main' set up to track 'origin/main'.
```

커밋 로그:

```
commit a9185ae ... (HEAD -> main, origin/main, origin/HEAD)
    chore: add .DS_Store to .gitignore
commit 0a243d9 ...
    docs: include GitHub VSCode image in documentation
commit 738cd81 ...
    init: add initial Dockerfile, README.md, and docker-compose.yml
```

캡처: [docs/images/github_vscode.png](docs/images/github_vscode.png), [docs/images/github_vsconde_commit_log.png](docs/images/github_vsconde_commit_log.png)

## 12. 트러블슈팅

### 트러블슈팅 1: `docker attach` 후 Ctrl+C를 눌러도 컨테이너가 종료되지 않음

- **문제**: `sleep 3600`을 메인 프로세스로 실행한 컨테이너에 `docker attach` 후 Ctrl+C를 여러 번 눌렀지만
  컨테이너가 계속 `Up` 상태였고, CLI는 `got 3 SIGTERM/SIGINTs, forcefully exiting`만 출력했다.
- **원인 가설**: Ctrl+C(SIGINT)가 컨테이너에 전달되지 않았거나 무시된 것으로 추정.
- **확인**: 리눅스 커널은 PID 1에 한해 핸들러가 등록되지 않은 시그널의 기본 동작을 적용하지 않는다.
  `sleep`은 SIGINT/SIGTERM 핸들러가 없어 PID 1로 실행되면 해당 시그널을 무시한다. 마지막 메시지는 컨테이너가
  아니라 **docker CLI가 attach 연결을 강제로 끊었다는 뜻**이었다.
- **해결/대안**: 메인 프로세스를 `bash`로 바꿔(`docker run -dit ubuntu bash`) `attach` 후 `exit` 명령으로
  종료 → 컨테이너가 정상적으로 `Exited` 상태가 됨을 확인. 동일 컨테이너에 `exec -it ... exit`을 했을 때는
  컨테이너가 살아있는 것과 비교해 attach/exec의 차이를 확인했다. (관련 캡처: 7번 섹션)

### 트러블슈팅 2

> TODO — 실습 중 겪은 다른 오류 1건을 같은 형식(문제 → 원인 가설 → 확인 → 해결/대안)으로 기록한다.
> 후보: 포트 충돌(port is already allocated), 컨테이너 이름 중복(name already in use),
> 바인드 마운트 경로 오타로 빈 페이지가 뜨는 경우 등.
