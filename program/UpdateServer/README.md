# Sistema di Aggiornamento Platinum+ Optimizer

Questo sistema gestisce l'aggiornamento automatico e incrementale (solo i file modificati) di Platinum+ Optimizer.
La struttura generata è pronta per essere caricata nella root `/program/` del tuo dominio Cloudflare Workers.

## Struttura della Cartella

- `install.ps1`: Script di bootstrap per installazioni da zero via internet.
- `updater.ps1`: Lo script che risiede sul client dell'utente e si occupa di confrontare hash, scaricare patch e riavviare l'app.
- `version.json`: Contiene la versione corrente e la data della build.
- `manifest-portable.json` / `manifest-setup.json`: Manifest con gli hash SHA-256 di tutti i file (separati per modalità).
- `files/Portable/`: Copia 1:1 di tutti i file necessari all'app in modalità Portable.
- `files/Setup/`: Copia 1:1 di tutti i file necessari all'app in modalità Setup.
- `scripts/`: Strumenti di build ad uso esclusivo dello sviluppatore.
  - `HashGenerator.ps1`: Modulo PowerShell per il calcolo degli hash.
  - `BuildManifest.ps1`: Script principale per eseguire la build.

## Come preparare un nuovo aggiornamento

1. Apri una finestra di PowerShell e spostati nella cartella `scripts`:
   ```powershell
   cd c:\Users\Admin\Desktop\platinum\setup\UpdateServer\scripts
   ```
2. Esegui lo script di build:
   ```powershell
   .\BuildManifest.ps1
   ```
   *Nota: Lo script incrementerà automaticamente la versione patch (es. 1.0.0 -> 1.0.1). Puoi forzare una versione specifica aggiungendo `-Version "1.1.0"`.*
3. Prendi TUTTO il contenuto della cartella `UpdateServer` (esclusa la cartella `scripts`, che serve solo a te) e caricalo su:
   `https://platinum.optimizer.workers.dev/program`

## Come integrare l'updater in Platinum+

All'interno dell'interfaccia grafica di Platinum+, per aggiungere un pulsante "Cerca Aggiornamenti", puoi semplicemente eseguire lo script `updater.ps1` (che ora viene copiato dall'installer o scaricato con l'installazione).

Esempio di comando per il bottone:
```powershell
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ModuleRoot\updater.ps1`"" -WorkingDirectory $ModuleRoot
```

L'updater gestirà tutto: chiusura di `run.ps1`, download incrementale basato su SHA-256, e riavvio automatico al termine.
