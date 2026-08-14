# Community Templates for the bash-based wpm

This directory contains **optional templates** for [wpm](https://github.com/Flashdown/wpm) – a transparent Bash-based Wine prefix manager.

The two templates that ship **inside the main script** (`cnc-gold` and `example-template`) are not present here, they remain for now the permanent default examples and will always be installed automatically by `wpm` itself.

---

## How to use a template from this folder

1. Download the desired `.sh` file (raw or via git clone).
2. Copy it into your local templates directory:

   ```bash
   mkdir -p ~/Wine/templates
   cp some-template.sh ~/Wine/templates/
   ```

3. Create a prefix with it:

   ```bash
   wpm create myprefix --template some-template
   ```

That’s it. No further registration is required.

4. list available templates:

   ```bash
   wpm templates
   ```


---

## Available example templates

| File                    | Description                                                                 | Author      |
|-------------------------|-----------------------------------------------------------------------------|-------------|
| `cnc-gold.sh`           | Command & Conquer Gold 1.06c + cnc-ddraw + CnCNet multiplayer (Wine 11.15) | Flashdown   |
| `example-template.sh`   | Fully commented skeleton showing every available hook                       | Flashdown   |


---

## Creating your own template

The easiest way is to start from `example-template.sh`.  
A minimal template looks like this:

```bash
# Template: My cool application

DEFAULT_WINE="11.15"          # optional – Kron4ek name, path or URL
DEFAULT_ARCH="64"             # optional – 32 or 64

WINETRICKS_DEPS="corefonts vcrun2022"   # optional

prepare_extra() {
    local prefix_path="$1"    # full path to the new/ existing prefix
    local wine_bin="$2"       # the wine binary that belongs to this prefix

    # Your extra steps here:
    # - registry edits
    # - DLL overrides
    # - running installers
    # - copying files
    # - additional winetricks calls
    # …
}
```

`prepare_extra` is called **after** the winetricks packages listed in `WINETRICKS_DEPS` have been installed. You can do almost anything inside it.

---

## Contributing

**Pull requests are very welcome!**

If you have a well-tested template for a game, application or runtime that others might find useful:

1. Fork the repository
2. Add your `my-app.sh` file to this `templates/` directory
3. Open a pull request

Please keep the template self-contained and try to document any manual steps (download links, required system packages, etc.) inside the file.

Thank you for helping to make this script more useful for everyone!
