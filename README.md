Our branch patterns are:

`v<number>.<number>.<number>@[dev|alpha|rc]`

...Whereby:

- latest @dev is the current branch being namely worked on
- @alpha is the release behind the latest @dev which is in user-testing and can come back with bugs which need to be worked on ASAP and each release increments the patch `<number>`
- @rc means no more bugs or work, its been submitted for app stores approval

So:

1. [v1.0.0@dev] *work happens*
2. v1.0.0@dev gets renamed to: v1.0.0@alpha
3. v1.0.0@alpha gets branched from to create v1.1.0@dev (and set to repo default branch)
4. PRs merged into v1.0.[1,2,...]@alpha get forwarded as PRs to v1.1.0@dev
5. Once testing bugs get resolved: the latest v1.0.[1,2,...]@alpha branch is renamed to v1.0.<latest_patch>@rc

---

Graphical representation

```
v1.0.0@dev              v1.1.0@dev

    -----------------    -----------------------...

                      \/                 /

                 v1.0.0@alpha           /

                       \               /

                       v1.0.<1...>@alpha

                         \

                         v1.0.<n>@rc
```