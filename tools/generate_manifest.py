from pathlib import Path
import json

script_dir = Path(__file__).resolve().parent
data_path = script_dir.parent / 'data.json'

# Load JSON data from external file
with data_path.open('r', encoding='utf-8') as f:
    data = json.load(f)

app_url_prefix = data['base_signed_url']

for device in data['devices']:
    output_dir = script_dir.parent / 'manifest' / device['id']
    output_dir.mkdir(parents=True, exist_ok=True)

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
for app in data['apps']:
    for device in data['devices']:
        plist_content = template.format(
            app_name=app['app_name'],
            app_id=app['app_id'],
            app_url=f"{app_url_prefix}/{device['id']}_{app['app_id']}_{app['app_version']}.ipa"
        )
        
        # Save to a file
        file_name = f"{app['app_id']}.plist"
        output_file = script_dir.parent / 'manifest' / device['id'] / file_name
        output_file.write_text(plist_content, encoding='utf-8')
        
        print(f"Generated: {device['id']}/{file_name}")