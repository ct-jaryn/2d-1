from PIL import Image
from pathlib import Path

INPUT_DIR = Path("assets/images")

TARGETS = {
    "battle_bg": (1280, 720),
    "boss_arena": (1280, 720),
    "shop_bg": (1280, 720),
    "panel_bg": (256, 256),
    "button_normal": (64, 64),
    "button_hover": (64, 64),
}


def process(name: str, target_size: tuple):
    files = list(INPUT_DIR.glob(f"{name}.*"))
    if not files:
        print(f"Skip {name}: not found")
        return
    path = files[0]
    img = Image.open(path).convert("RGBA")
    img = img.resize(target_size, Image.Resampling.LANCZOS)
    out_path = INPUT_DIR / f"{name}.png"
    img.save(out_path)
    print(f"Processed {name} -> {out_path} ({img.size})")


def main():
    for name, size in TARGETS.items():
        process(name, size)
    print("Done")


if __name__ == "__main__":
    main()
