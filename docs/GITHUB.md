# Git และ GitHub

อ่านไฟล์นี้ก่อนรันคำสั่ง git ที่เปลี่ยนอะไรก็ตาม (commit, push, branch, merge)

## ข้อมูล repo

| เรื่อง | ค่า |
|---|---|
| Repo | `https://github.com/Qcutedev/Project-Sleep` |
| ที่อยู่ในเครื่อง | `C:\Project SLEEP\sleepwise_ai` |
| Branch หลัก | `main` |
| ผู้เขียน commit | `Qcutedev <qcutedev@gmail.com>` (ตั้งไว้เฉพาะ repo นี้) |

- **โฟลเดอร์ `C:\Project SLEEP` ไม่ใช่ git repo** ถ้ารัน git ที่นั่นจะขึ้น `fatal: not a git repository` ต้อง `cd` เข้า `sleepwise_ai` ก่อน
- Repo เคยอยู่ที่บัญชี `kiwnoz` แล้วย้ายมา `Qcutedev` remote ในเครื่องชี้ที่อยู่ใหม่แล้ว
- เครื่องนี้ไม่มี `gh` การเปิดและ merge Pull Request ทำบนเว็บ GitHub

## ขั้นตอนทำงาน

**หนึ่งเรื่อง หนึ่ง branch** ฟีเจอร์ใหม่ หรือการแก้บั๊กคนละเรื่อง ต้องแตก branch ใหม่จาก `main` เสมอ ห้ามทำหลายเรื่องรวมใน branch เดียว

```bash
git checkout main
git pull
git checkout -b feature/ชื่อเรื่อง
# ...ทำงาน...
git add <ไฟล์ที่เกี่ยวข้อง>
git commit
git push -u origin feature/ชื่อเรื่อง
```

จากนั้นเจ้าของโปรเจคเปิด Pull Request บนเว็บแล้ว merge เข้า `main` หลัง merge ให้ `git checkout main` แล้ว `git pull`

### ชื่อ branch

| ประเภท | รูปแบบ | ตัวอย่าง |
|---|---|---|
| ฟีเจอร์ใหม่ | `feature/<ชื่อ>` | `feature/thai-localization` |
| แก้บั๊ก | `fix/<ชื่อ>` | `fix/alarm-list-spinner` |
| เอกสาร | `docs/<ชื่อ>` | `docs/project-guides` |

ใช้ตัวพิมพ์เล็กภาษาอังกฤษ คั่นคำด้วยขีดกลาง

ถ้าอยู่กลางงานแล้วเจ้าของโปรเจคขอเรื่องใหม่ที่ไม่เกี่ยวกัน ให้ commit งานเดิมก่อน แล้วแตก branch ใหม่จาก `main` สำหรับเรื่องใหม่ ถ้าไม่แน่ใจว่าเป็นเรื่องเดียวกันหรือไม่ ให้ถาม

## ข้อความ commit

- **เป็นภาษาอังกฤษ** เจ้าของโปรเจคต้องการแบบนี้ (commit เก่าบางอันเป็นภาษาไทย ไม่ต้องตาม)
- บรรทัดแรกสรุปว่าทำอะไร ขึ้นต้นด้วยกริยา ไม่เกินราว 72 ตัวอักษร เช่น `Add sleep stats screen`
- ถ้ามีหลายอย่าง เว้นบรรทัดแล้วเขียนเป็นข้อย่อย
- ปิดท้ายด้วยบรรทัด `Co-Authored-By` ตามที่ Claude Code กำหนดในเซสชันนั้น
- commit ให้เล็กและตรงเรื่อง ไม่รวมการแก้ที่ไม่เกี่ยวกัน

## ต้องได้รับคำสั่งก่อน

ทำเมื่อเจ้าของโปรเจคสั่งเท่านั้น ห้ามทำเองระหว่างทำงานอื่น:

- `git commit`
- `git push`
- เปิดหรือ merge Pull Request
- แก้ `git config`

คำสั่งที่แค่อ่าน (`git status`, `git log`, `git diff`, `git fetch`, `git ls-remote`) รันได้เลย

## ห้ามทำเอง

คำสั่งพวกนี้ย้อนกลับยาก Claude Code ถูกตั้งให้บล็อกไว้ และ **ห้ามหาทางอ้อมไปทำ**:

- `git push --force` และ `--force-with-lease`
- `git commit --amend` กับ commit ที่ push ไปแล้ว
- `git rebase`, `git filter-branch`, `git reset --hard` กับ commit ที่ push ไปแล้ว
- ลบ branch บน GitHub
- push ตรงเข้า `main`

ถ้าจำเป็นจริง ให้อธิบายผลที่ตามมา แล้วเขียนคำสั่งให้เจ้าของโปรเจครันเองใน Terminal

## เขียนคำสั่งให้เจ้าของโปรเจครันเอง

เจ้าของโปรเจคใช้ PowerShell ใน VS Code และไม่ถนัด git ให้เขียนแบบนี้:

- ขึ้นต้นด้วย `cd "C:\Project SLEEP\sleepwise_ai"` เสมอ เพราะ Terminal มักเปิดที่โฟลเดอร์แม่
- ให้คำสั่งตรวจผลตามหลังทุกครั้ง เช่น `git log -1` และบอกว่าควรเห็นอะไร
- **ห้ามมีเครื่องหมายคำพูดคู่ `"` อยู่ในข้อความที่ครอบด้วย `'...'`** PowerShell 5.1 จะตัดอาร์กิวเมนต์ผิดตำแหน่ง แล้ว git จะมองคำที่เหลือเป็นชื่อไฟล์ (`error: pathspec ... did not match`)
- ข้อความ commit หลายบรรทัด ให้ใช้ `-m '...'` หลายตัว แต่ละตัวจะเป็นย่อหน้าแยก
- PowerShell 5.1 ไม่มี `&&` ให้แยกเป็นคนละบรรทัด

## สิ่งที่อยู่ใน history และตกลงกันว่าปล่อยไว้

ไม่ต้องเสนอแก้ซ้ำ:

- commit เก่าที่ผู้เขียนเป็น `kiwnoz` / `kiw <kiwnoz0242@gmail.com>` และข้อความ `Merge pull request #2 from kiwnoz/...` เป็นบัญชีเก่าของเจ้าของโปรเจคเอง
- `main` มี commit `4726dd4` ที่ข้อความเป็นภาษาไทย (เข้ามาทาง PR #3) ส่วน branch `feature/new-screens` มี commit `ec4905b` ซึ่งเนื้อโค้ดเหมือนกันทุกบรรทัดแต่ข้อความเป็นอังกฤษ สองอันนี้ต่างกันแค่ข้อความ
- การทำให้ `main` สะอาดต้อง force push ทับ `main` ซึ่งเจ้าของโปรเจคเลือกไม่ทำ

## ห้าม commit

- `build/`, ไฟล์ `.apk` (อยู่ใน `.gitignore` แล้ว)
- เทสต์ชั่วคราวและรูปที่สร้างตอนตรวจ UI (`test/tmp_*`, `test/shots/`)
- รหัสผ่าน token หรือไฟล์ `.env`
- IP ของเครื่อง หรือ path ที่ผูกกับเครื่องนี้ในโค้ดแอป

ใช้ `git add <ไฟล์>` ระบุไฟล์ หรือดู `git status` ก่อนใช้ `git add -A` ทุกครั้ง
