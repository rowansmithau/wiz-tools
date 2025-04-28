# Shell aliases to make life easier

Put these in your ~/.zshrc / ~/.bashrc. Make sure the path makes sense for your system.

sc = shikari create
ss = shikari shell
sd = shikari delete

```
# shikari quick commands
sc() {
  (
    cd "/Users/rowan/Downloads/wiz-git/wiz-tools/shikari-scenarios/scenarios/empty" && 
    shikari create -n wiz -s 1
  )
}

sd() {
  (
    cd "/Users/rowan/Downloads/wiz-git/wiz-tools/shikari-scenarios/scenarios/empty" && 
    shikari destroy -n wiz -f
  )
}

ss() {
  shikari shell wiz-srv-01
}

scu() {
  (
    cd "/Users/rowan/Downloads/wiz-git/wiz-tools/shikari-scenarios/scenarios/empty-ubuntu" && 
    shikari create -n wizubuntu -s 1
  )
}

sdu() {
  (
    cd "/Users/rowan/Downloads/wiz-git/wiz-tools/shikari-scenarios/scenarios/empty-ubuntu" && 
    shikari destroy -n wizubuntu -f
  )
}

ssu() {
  shikari shell wizubuntu-srv-01
}

scu22() {
  (
    cd "/Users/rowan/Downloads/wiz-git/wiz-tools/shikari-scenarios/scenarios/empty-ubuntu-22" && 
    shikari create -n wizubuntu22 -s 1
  )
}

sdu22() {
  (
    cd "/Users/rowan/Downloads/wiz-git/wiz-tools/shikari-scenarios/scenarios/empty-ubuntu-22" && 
    shikari destroy -n wizubuntu22 -f
  )
}

ssu22() {
  shikari shell wizubuntu22-srv-01
}
```