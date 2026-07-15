# Website Update: Featured Videos

We need a new "featured on" section about GameFromScratch.

We were featured in a video by `Code It All`.
Video: https://www.youtube.com/watch?v=EpQFuLRavv4
No article.

Keep this summary.
Track below.

## Checklist

- [x] Add the Code It All featured video to the homepage featured coverage section.
- [x] Preserve the existing GameFromScratch video and article links.
- [x] Verify the website build and canonical validation.
- [x] Update this plan with completion status and validation notes.
- [x] Move Code It All above the GameFromScratch coverage card.

## Validation

- `yarn build:web` passed.
- Canonical validation passed.
- Confirmed `dist/website/index.html` contains the `Code It All` card, the `https://www.youtube.com/watch?v=EpQFuLRavv4` video link, and the existing GameFromScratch video/article links.
- Attempted an in-app browser visual check, but the browser connector failed to initialize because its runtime metadata was missing `sandboxPolicy`.
- Re-ran `yarn build:web` after reordering; build and canonical validation passed.
- Confirmed `dist/website/index.html` emits `Code It All` before `GameFromScratch`.
