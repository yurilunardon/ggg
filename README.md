# HandyShots MVP

<img src="https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg" alt="Platform: macOS 13.0+">
<img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
<img src="https://img.shields.io/badge/version-1.0.0-green.svg" alt="Version 1.0.0">

**HandyShots** è una menu bar application per macOS che monitora la cartella screenshot e fornisce accesso rapido alle tue catture schermo.

## 📋 Caratteristiche MVP

- ✅ **Menu Bar Application** - Icona persistente nella barra menu
- ✅ **Rilevamento Automatico** - Trova automaticamente la cartella screenshot di sistema
- ✅ **Monitoraggio Cartella** - Polling continuo per rilevare cambi di cartella
- ✅ **Welcome Screen** - Setup guidato al primo avvio
- ✅ **Settings Window** - Configurazione del tempo di visualizzazione (5-60 minuti)
- ✅ **Popover Interface** - Interfaccia pulita e nativa macOS
- ✅ **Selezione Cartella Custom** - Possibilità di scegliere una cartella personalizzata

## 🛠️ Requisiti

- **macOS**: 13.0 (Ventura) o superiore
- **Xcode**: 15.0 o superiore
- **Swift**: 5.9 o superiore
- **SwiftUI**: 4.0 o superiore

## 📦 Struttura del Progetto

```
HandyShots/
├── HandyShotsApp.swift          # Entry point + AppDelegate
├── Views/
│   ├── PopoverView.swift        # Interfaccia principale
│   ├── WelcomeView.swift        # Schermata primo avvio
│   └── SettingsView.swift       # Finestra impostazioni
├── Utilities/
│   ├── FolderDetector.swift     # Rilevamento cartella screenshot
│   └── FolderMonitor.swift      # Monitoraggio cambiamenti
└── Resources/
    ├── Info.plist               # Configurazioni bundle
    └── HandyShots.entitlements  # Sandbox capabilities
```

## 🚀 Quick Start - Build Automatico (CONSIGLIATO)

**Modo più semplice per compilare e lanciare l'app:**

```bash
# Dalla root del progetto
./scripts/fresh-build.sh
```

Questo script fa TUTTO automaticamente:
1. ✅ Pulisce tutte le build precedenti
2. ✅ Rimuove app installate
3. ✅ Resetta UserDefaults e permessi
4. ✅ Compila da zero in Release mode
5. ✅ Crea un .app bundle standalone pronto all'uso
6. ✅ Ti chiede se vuoi lanciare l'app immediatamente

**Risultato:** Troverai l'app in `build/HandyShots.app` pronta per essere aperta!

**Per maggiori dettagli:** Vedi [scripts/README.md](scripts/README.md)

---

## 🚀 Setup e Build Manuale

### Opzione 1: Xcode (Alternativa manuale)

1. **Apri Xcode** e crea un nuovo progetto:
   - File → New → Project
   - Seleziona "App" sotto macOS
   - Nome: `HandyShots`
   - Interface: SwiftUI
   - Language: Swift
   - Bundle Identifier: `com.handyshots.app`

2. **Copia i file** nella struttura corretta:
   ```bash
   # Dalla root del repository
   # Copia tutti i file Swift e Resources nella cartella del progetto Xcode
   ```

3. **Configura le Capabilities**:
   - Seleziona il target → Signing & Capabilities
   - Aggiungi "App Sandbox"
   - Abilita:
     - User Selected File (Read Only)
     - Outgoing Connections (Client)

4. **Configura Info.plist**:
   - Sostituisci Info.plist con quello in `Resources/`
   - Assicurati che `LSUIElement` sia `YES` per nascondere dal Dock

5. **Aggiungi Entitlements**:
   - Aggiungi il file `HandyShots.entitlements` al progetto
   - In Build Settings, imposta Code Sign Entitlements su questo file

6. **Build e Run**:
   - Product → Build (⌘B)
   - Product → Run (⌘R)

### Opzione 2: Swift Package Manager

```bash
# Build
swift build -c release

# Note: SPM non supporta completamente le app macOS con UI
# Questa opzione è principalmente per test di compilazione
```

---

## 🛠️ Script Disponibili

Il progetto include script automatici per semplificare il workflow:

### `./scripts/fresh-build.sh` ⭐ PRINCIPALE
Build completo da zero con cleanup totale.

### `./scripts/clean.sh`
Pulisce build, cache, UserDefaults e permessi.

### `./scripts/build.sh`
Compila l'app senza cleanup.

**Documentazione completa:** [scripts/README.md](scripts/README.md)

---

## 🎯 Come Usare

### Primo Avvio

1. L'app appare nella **menu bar** con l'icona 📷
2. **Click sinistro** sull'icona per aprire il popover
3. Vedrai la **Welcome Screen** con la cartella rilevata automaticamente
4. Scegli:
   - **"Use This Folder"** - Usa la cartella rilevata
   - **"Choose Another Folder"** - Seleziona una cartella custom

### Utilizzo Normale

- **Left Click** → Apre popover principale
- **Right Click** → Apre menu contestuale
  - Settings → Apre finestra impostazioni
  - Quit → Chiude l'applicazione

### Impostazioni

- **Display Time**: Imposta quanti minuti mostrare gli screenshot (5-60 min)
- Le preferenze vengono salvate automaticamente

## 📁 Rilevamento Cartella Screenshot

L'app rileva la cartella screenshot in questo ordine:

1. **Preferenze Sistema**: Legge `com.apple.screencapture.location`
2. **Fallback**: Usa `~/Desktop`
3. **Monitoring**: Controlla ogni 5 secondi se la cartella è cambiata

## 💾 Persistenza Dati

I dati vengono salvati in `UserDefaults`:

| Key | Tipo | Default | Descrizione |
|-----|------|---------|-------------|
| `screenshotFolder` | String | "" | Path cartella screenshot |
| `isFirstLaunch` | Bool | true | Flag primo avvio |
| `timeFilter` | Int | 10 | Minuti filtro temporale |

## 🧪 Testing

### Checklist Manuale

- [ ] App appare nella menu bar dopo il lancio
- [ ] Left click apre il popover
- [ ] Right click apre il context menu
- [ ] Prima apertura mostra welcome screen
- [ ] Selezione cartella funziona correttamente
- [ ] Settings window si apre e salva preferenze
- [ ] Slider tempo funziona (5-60 minuti)
- [ ] Monitor rileva cambi cartella sistema
- [ ] App non crasha quando si chiude il popover
- [ ] App termina correttamente da Quit menu

### Test su Sistema

```bash
# Cambia cartella screenshot di sistema
defaults write com.apple.screencapture location ~/Pictures

# Controlla la cartella attuale
defaults read com.apple.screencapture location

# Resetta al default (Desktop)
defaults delete com.apple.screencapture location
```

## 🐛 Troubleshooting

### App non appare nella menu bar
- Verifica che `LSUIElement` sia impostato su `YES` in Info.plist
- Controlla che l'AppDelegate stia creando lo statusItem

### Cartella screenshot non rilevata
- Verifica le permission del filesystem
- Controlla i log della console per errori

### Settings non si salvano
- Verifica che UserDefaults stia funzionando correttamente
- Controlla che il sandbox non blocchi l'accesso

## 🔮 Future Features (Non MVP)

Le seguenti funzionalità sono previste per versioni future:

- Screenshot thumbnails display
- Quick Look integration
- Drag & drop support
- OCR text recognition
- Screenshot annotation
- Cloud sync
- Hotkey shortcuts
- Advanced filtering options

## 📄 License

Copyright © 2025 HandyShots. All rights reserved.

## 🆘 Support

Per problemi o domande:

1. Verifica la console di Xcode per log/errori
2. Controlla le permission del sistema
3. Verifica la versione di macOS (min 13.0)

## 📝 Note di Sviluppo

- **Sandbox**: L'app usa App Sandbox per sicurezza
- **Permissions**: Richiede accesso a file selezionati dall'utente
- **Polling**: Usa Timer per monitorare cambiamenti (ogni 5s)
- **Persistenza**: UserDefaults per semplicità del MVP
- **UI**: 100% SwiftUI nativo per consistenza macOS

---

**Versione**: 1.0.0 MVP
**Data**: Ottobre 2025
**Piattaforma**: macOS 13.0+
