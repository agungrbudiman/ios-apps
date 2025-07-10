from pathlib import Path
import json

script_dir = Path(__file__).resolve().parent
data_path = script_dir.parent / 'data.json'
output_dir = script_dir.parent / 'manifest'

output_dir.mkdir(parents=True, exist_ok=True)

# Load JSON data from external file
with data_path.open('r', encoding='utf-8') as f:
    apps = json.load(f)

# plist template with placeholders
template = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>items</key>
        <array>
            <dict>
                <key>assets</key>
                <array>
                    <dict>
                        <key>kind</key>
                        <string>software-package</string>
                        <key>url</key>
                        <string>{app_url}</string>
                    </dict>
                </array>
                <key>metadata</key>
                <dict>
                    <key>bundle-identifier</key>
                    <string>{app_id}</string>
                    <key>bundle-version</key>
                    <string>2.0</string>
                    <key>kind</key>
                    <string>software</string>
                    <key>title</key>
                    <string>{app_name}</string>
                </dict>
            </dict>
        </array>
    </dict>
</plist>'''

# Generate plist for each app
for app in apps:
    plist_content = template.format(
        app_name=app["app_name"],
        app_id=app["app_id"],
        app_url=app["app_url"]
    )
    
    # Save to a file
    file_name = f"{app['device']}_{app['app_id']}.plist"
    output_file = output_dir / file_name
    output_file.write_text(plist_content, encoding='utf-8')
    
    print(f"Generated: {file_name}")