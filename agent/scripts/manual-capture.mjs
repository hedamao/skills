import fs from "node:fs/promises";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2];
const outDir = process.argv[3];

if (!url || !outDir) {
  console.error("Usage: node scripts/manual-capture.mjs <url> <outDir>");
  process.exit(1);
}

await fs.mkdir(path.join(outDir, "screenshots"), { recursive: true });
await fs.mkdir(path.join(outDir, "extracted"), { recursive: true });
await fs.mkdir(path.join(outDir, "assets"), { recursive: true });

const browser = await chromium.launch({
  headless: true,
  executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
});
const page = await browser.newPage({
  viewport: { width: 390, height: 844, isMobile: true },
  userAgent:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
});

await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
await page.waitForTimeout(8000);

await page.screenshot({
  path: path.join(outDir, "screenshots", "scroll-000.png"),
  fullPage: true,
});
await page.screenshot({
  path: path.join(outDir, "screenshots", "viewport-000.png"),
  fullPage: false,
});

const data = await page.evaluate(() => {
  const visible = (el) => {
    const style = getComputedStyle(el);
    const rect = el.getBoundingClientRect();
    return (
      style.visibility !== "hidden" &&
      style.display !== "none" &&
      Number(style.opacity) > 0 &&
      rect.width > 0 &&
      rect.height > 0
    );
  };

  const textLines = [];
  document.querySelectorAll("h1,h2,h3,h4,p,a,button,li,span").forEach((el) => {
    if (!visible(el)) return;
    const text = (el.innerText || el.textContent || "").replace(/\s+/g, " ").trim();
    if (text && text.length <= 180) {
      textLines.push(`[${el.tagName.toLowerCase()}] ${text}`);
    }
  });

  const colors = new Map();
  const fonts = new Map();
  document.querySelectorAll("*").forEach((el) => {
    if (!visible(el)) return;
    const style = getComputedStyle(el);
    [style.color, style.backgroundColor, style.borderColor].forEach((value) => {
      if (!value || value === "rgba(0, 0, 0, 0)" || value === "transparent") return;
      colors.set(value, (colors.get(value) || 0) + 1);
    });
    const family = style.fontFamily;
    const weight = style.fontWeight;
    if (family) {
      const current = fonts.get(family) || new Set();
      current.add(weight);
      fonts.set(family, current);
    }
  });

  const assets = [];
  document.querySelectorAll("img,svg,video,source").forEach((el, index) => {
    const src = el.currentSrc || el.src || el.getAttribute("src") || "";
    const alt = el.getAttribute("alt") || "";
    const rect = el.getBoundingClientRect();
    assets.push({
      index,
      tag: el.tagName.toLowerCase(),
      src,
      alt,
      width: Math.round(rect.width),
      height: Math.round(rect.height),
    });
  });

  return {
    title: document.title,
    location: location.href,
    textLines: [...new Set(textLines)],
    colors: [...colors.entries()].sort((a, b) => b[1] - a[1]),
    fonts: [...fonts.entries()].map(([family, weights]) => [family, [...weights].sort()]),
    assets,
    html: document.documentElement.outerHTML.slice(0, 250000),
  };
});

await fs.writeFile(
  path.join(outDir, "extracted", "visible-text.txt"),
  data.textLines.join("\n") + "\n",
);
await fs.writeFile(
  path.join(outDir, "extracted", "tokens.json"),
  JSON.stringify(
    {
      title: data.title,
      url: data.location,
      colors: data.colors,
      fonts: data.fonts,
      sections: 1,
      headings: data.textLines.filter((line) => /^\[h[1-4]\]/.test(line)).length,
      ctas: data.textLines.filter((line) => /^\[(a|button)\]/.test(line)).length,
    },
    null,
    2,
  ),
);
await fs.writeFile(
  path.join(outDir, "extracted", "asset-descriptions.md"),
  data.assets
    .map(
      (asset) =>
        `- asset-${asset.index} (${asset.tag}, ${asset.width}x${asset.height}) — ${asset.alt || "no alt text"} ${asset.src}`,
    )
    .join("\n") + "\n",
);
await fs.writeFile(
  path.join(outDir, "extracted", "assets-catalog.json"),
  JSON.stringify(data.assets, null, 2),
);
await fs.writeFile(path.join(outDir, "extracted", "page.html"), data.html);

await browser.close();
