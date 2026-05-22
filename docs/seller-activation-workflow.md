# Seller Activation Workflow

MacCtrlCVA now includes a local seller-side activation generator with GUI prompts and local issuance records.

## Files

- `scripts/generate-activation-code.command`: double-clickable GUI seller tool
- `scripts/generate-activation-code.swift`: underlying signing script
- `Keys/activation-private-key.txt`: private key used to issue activation codes
- `Keys/activation-records.json`: local issuance history generated automatically

## How To Use

1. Ask the customer to open `Copy Machine Code` from the MacCtrlCVA menu bar app
2. The customer sends you their machine code
3. Double-click `scripts/generate-activation-code.command`
4. Paste the first machine code
5. If you want one activation code to work on two Macs, paste a second machine code too
6. Optionally add a note such as buyer nickname, order ID, or platform
7. The tool generates the activation code and stores a local record automatically
8. Send the activation code back to the customer
9. The customer opens `Activation Settings` and pastes the code

## Important

- `Keys/activation-private-key.txt` must stay private
- Back up the private key before selling licenses
- If you lose the private key, you cannot issue new activation codes compatible with the current app
- `Keys/activation-records.json` is your local issuance history and should be backed up too
