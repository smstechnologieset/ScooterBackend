import os
from PIL import Image, ImageDraw

def create_app_icon(logo_path, size, bg_color=(12, 16, 14, 255), padding_ratio=0.18, is_round=False):
    """Generate a high-quality app icon with given dimensions."""
    img = Image.new('RGBA', (size, size), bg_color)
    
    # Load and crop logo to non-empty bounding box
    logo = Image.open(logo_path).convert('RGBA')
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
        
    logo_w, logo_h = logo.size
    
    # Calculate fit within safe area
    target_max = int(size * (1.0 - 2 * padding_ratio))
    scale = min(target_max / logo_w, target_max / logo_h)
    new_w = max(1, int(logo_w * scale))
    new_h = max(1, int(logo_h * scale))
    
    resized_logo = logo.resize((new_w, new_h), Image.LANCZOS)
    
    # Center the logo
    offset_x = (size - new_w) // 2
    offset_y = (size - new_h) // 2
    img.paste(resized_logo, (offset_x, offset_y), resized_logo)
    
    if is_round:
        # Create circular mask
        mask = Image.new('L', (size, size), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, size - 1, size - 1), fill=255)
        
        round_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        round_img.paste(img, (0, 0), mask)
        return round_img
        
    return img

def create_foreground_icon(logo_path, size, padding_ratio=0.28):
    """Generate an adaptive icon foreground (transparent background)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    logo = Image.open(logo_path).convert('RGBA')
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
        
    logo_w, logo_h = logo.size
    
    # Safe center area for adaptive icons (typically center 66%)
    target_max = int(size * (1.0 - 2 * padding_ratio))
    scale = min(target_max / logo_w, target_max / logo_h)
    new_w = max(1, int(logo_w * scale))
    new_h = max(1, int(logo_h * scale))
    
    resized_logo = logo.resize((new_w, new_h), Image.LANCZOS)
    
    offset_x = (size - new_w) // 2
    offset_y = (size - new_h) // 2
    img.paste(resized_logo, (offset_x, offset_y), resized_logo)
    return img

def create_splash_square_logo(logo_path, canvas_size, padding_ratio=0.18):
    """Generate a 1:1 perfectly square canvas splash logo with transparent background and centered un-stretched logo."""
    img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    
    logo = Image.open(logo_path).convert('RGBA')
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
    
    logo_w, logo_h = logo.size
    target_max = int(canvas_size * (1.0 - 2 * padding_ratio))
    scale = min(target_max / logo_w, target_max / logo_h)
    new_w = max(1, int(logo_w * scale))
    new_h = max(1, int(logo_h * scale))
    
    resized_logo = logo.resize((new_w, new_h), Image.LANCZOS)
    offset_x = (canvas_size - new_w) // 2
    offset_y = (canvas_size - new_h) // 2
    img.paste(resized_logo, (offset_x, offset_y), resized_logo)
    return img

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    logo_path = os.path.join(base_dir, 'assets', 'images', 'logo.png')
    
    if not os.path.exists(logo_path):
        print(f"Error: Logo not found at {logo_path}")
        return
        
    print(f"Found logo at: {logo_path}")
    
    # ─── 1. Android Mipmap Icons & Splash ──────────────────────────────────────
    android_res = os.path.join(base_dir, 'android', 'app', 'src', 'main', 'res')
    
    # density: (launcher_size, adaptive_fg_size, square_splash_size)
    android_densities = {
        'mipmap-mdpi': (48, 108, 192),
        'mipmap-hdpi': (72, 162, 288),
        'mipmap-xhdpi': (96, 216, 384),
        'mipmap-xxhdpi': (144, 324, 576),
        'mipmap-xxxhdpi': (192, 432, 768),
    }
    
    for folder, (launcher_sz, fg_sz, splash_sz) in android_densities.items():
        folder_path = os.path.join(android_res, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Standard ic_launcher.png
        icon = create_app_icon(logo_path, launcher_sz, padding_ratio=0.15)
        icon.save(os.path.join(folder_path, 'ic_launcher.png'), 'PNG')
        
        # Round ic_launcher_round.png
        round_icon = create_app_icon(logo_path, launcher_sz, padding_ratio=0.18, is_round=True)
        round_icon.save(os.path.join(folder_path, 'ic_launcher_round.png'), 'PNG')
        
        # Adaptive foreground
        fg_icon = create_foreground_icon(logo_path, fg_sz, padding_ratio=0.28)
        fg_icon.save(os.path.join(folder_path, 'ic_launcher_foreground.png'), 'PNG')
        
        # Perfectly square 1:1 launch_image.png (avoids any stretching on Android 12+ or legacy layer-list)
        splash_img = create_splash_square_logo(logo_path, splash_sz, padding_ratio=0.18)
        splash_img.save(os.path.join(folder_path, 'launch_image.png'), 'PNG')
        print(f"Generated Android {folder} (Launcher: {launcher_sz}px, FG: {fg_sz}px, Square Splash: {splash_sz}x{splash_sz}px)")
        
    # Generate drawable folder splash_logo.png (512x512 square)
    drawable_folder = os.path.join(android_res, 'drawable')
    os.makedirs(drawable_folder, exist_ok=True)
    splash_def = create_splash_square_logo(logo_path, 512, padding_ratio=0.18)
    splash_def.save(os.path.join(drawable_folder, 'splash_logo.png'), 'PNG')
    
    # ─── 2. iOS App Icons ──────────────────────────────────────────────────────
    ios_icons_dir = os.path.join(base_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(ios_icons_dir):
        ios_sizes = {
            'Icon-App-20x20@1x.png': 20,
            'Icon-App-20x20@2x.png': 40,
            'Icon-App-20x20@3x.png': 60,
            'Icon-App-29x29@1x.png': 29,
            'Icon-App-29x29@2x.png': 58,
            'Icon-App-29x29@3x.png': 87,
            'Icon-App-40x40@1x.png': 40,
            'Icon-App-40x40@2x.png': 80,
            'Icon-App-40x40@3x.png': 120,
            'Icon-App-60x60@2x.png': 120,
            'Icon-App-60x60@3x.png': 180,
            'Icon-App-76x76@1x.png': 76,
            'Icon-App-76x76@2x.png': 152,
            'Icon-App-83.5x83.5@2x.png': 167,
            'Icon-App-1024x1024@1x.png': 1024,
        }
        for filename, sz in ios_sizes.items():
            icon = create_app_icon(logo_path, sz, padding_ratio=0.15)
            icon.save(os.path.join(ios_icons_dir, filename), 'PNG')
            print(f"Generated iOS icon {filename} ({sz}px)")
            
    # ─── 3. iOS Launch Images ──────────────────────────────────────────────────
    ios_launch_dir = os.path.join(base_dir, 'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset')
    if os.path.exists(ios_launch_dir):
        create_splash_square_logo(logo_path, 300, padding_ratio=0.15).save(os.path.join(ios_launch_dir, 'LaunchImage.png'), 'PNG')
        create_splash_square_logo(logo_path, 600, padding_ratio=0.15).save(os.path.join(ios_launch_dir, 'LaunchImage@2x.png'), 'PNG')
        create_splash_square_logo(logo_path, 900, padding_ratio=0.15).save(os.path.join(ios_launch_dir, 'LaunchImage@3x.png'), 'PNG')
        print("Generated iOS Launch Images")
        
    print("\nAll launcher icons and square splash assets successfully generated!")

if __name__ == '__main__':
    main()
