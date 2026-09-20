# Getting Started with Create React App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.\
You will also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**

If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

## TikTok Profile Lookup

The landing page (`src/TikTokLookup.tsx`) takes a TikTok username and shows the
profile picture, plus a coin number you type yourself. The DommerJob login screen
still lives at `#/dommer`.

### How the picture is fetched, and why it can fail

TikTok publishes no public, CORS-enabled API for "username -> avatar", and a
browser cannot fetch `tiktok.com` directly (no `Access-Control-Allow-Origin`
header). Since this site is deployed as static files on GitHub Pages, there is no
backend to proxy through, so `src/tiktok.ts` tries a handful of public CORS
proxies and parses the avatar out of the profile HTML.

That is best-effort: TikTok often serves a bot-check page to datacenter IPs, and
the public proxies rate-limit. When every proxy fails the card is still shown -
with the username, a link to the profile and the option to set the picture from a
file or an image URL.

### Making it reliable

Point the app at your own endpoint:

```
REACT_APP_TIKTOK_API=https://your-function.example.com/tiktok
```

It is called as `?username=xyz` and should answer with
`{ "avatarUrl": "...", "nickname": "...", "followerCount": 123 }`. It is tried
first, and the public proxies stay as a fallback. Note that this needs a host
that runs code - GitHub Pages alone cannot do it.

### Note on the coin number

The coin field is a label you type onto the card. It is not a balance, it reads
nothing from TikTok and it changes nothing on TikTok.
