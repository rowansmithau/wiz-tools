# WizCLI downloader

This will check if your WizCLI install is out of date, and if so, install the latest version.
It will also check if you have WizCLI installed and if not, download it.

And a `.zshrc` or `.bashrc` function to easily call it, just set your own `SCRIPT_PATH`:

```
wizcli_update() {
    SCRIPT_PATH="~/Downloads/wiz-git/wiz-tools/wizcli/wizcli-latest.sh"

    if [ ! -x "$SCRIPT_PATH" ]; then
        echo "Error: $SCRIPT_PATH is not executable."
        return 1
    fi

    bash "$SCRIPT_PATH"
}
```