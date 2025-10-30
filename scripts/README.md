# HandyShots Build Scripts

Questi script automatizzano il processo di build completo per HandyShots.

## 📜 Script Disponibili

### 🚀 `fresh-build.sh` - **QUESTO È LO SCRIPT PRINCIPALE**

Script master che esegue tutto il pipeline di build da zero.

**Cosa fa:**
1. Pulisce completamente build e cache
2. Rimuove app installate precedentemente
3. Resetta UserDefaults e preferenze
4. Cancella permessi dell'app (TCC)
5. Compila l'app da zero
6. Crea un .app bundle standalone
7. Firma l'applicazione

**Come usare:**
```bash
cd scripts
./fresh-build.sh
```

Oppure dalla root del progetto:
```bash
./scripts/fresh-build.sh
```

**Output:**
- `.app` bundle pronto all'uso in `build/HandyShots.app`
- Lo script chiederà se vuoi lanciare l'app immediatamente

---

### 🧹 `clean.sh` - Script di Pulizia

Pulisce tutto senza ricompilare.

**Cosa fa:**
- Rimuove `.build/` e DerivedData
- Cancella app installate
- Resetta UserDefaults (`com.handyshots.app`)
- Cancella permessi TCC
- Pulisce cache Xcode e SPM

**Come usare:**
```bash
./scripts/clean.sh
```

**Quando usare:**
- Prima di un fresh build manuale
- Per resettare l'app allo stato iniziale
- Per liberare spazio su disco

---

### 🔨 `build.sh` - Script di Build

Compila l'app senza pulire prima.

**Cosa fa:**
- Verifica prerequisiti (Swift, Xcode)
- Compila con `swift build -c release`
- Crea struttura .app bundle
- Copia Info.plist e resources
- Firma l'applicazione

**Come usare:**
```bash
./scripts/build.sh
```

**Quando usare:**
- Build veloce senza cleanup
- Test di compilazione
- Dopo modifiche al codice

---

## 🎯 Quick Start

**Prima build:**
```bash
./scripts/fresh-build.sh
```

**Build successive (dopo modifiche al codice):**
```bash
./scripts/build.sh
```

**Reset completo:**
```bash
./scripts/clean.sh
./scripts/build.sh
```

---

## 📋 Requisiti

- **macOS**: 13.0+ (Ventura o superiore)
- **Xcode**: 15.0+ con Command Line Tools
- **Swift**: 5.9+

Verifica che Xcode sia installato:
```bash
xcode-select --version
swift --version
```

Se mancano i Command Line Tools:
```bash
xcode-select --install
```

---

## 📦 Output

Dopo il build, troverai l'app qui:
```
build/HandyShots.app
```

### Come lanciare l'app:

**Opzione 1 - Da terminale:**
```bash
open build/HandyShots.app
```

**Opzione 2 - Da Finder:**
1. Naviga alla cartella `build/`
2. Doppio click su `HandyShots.app`

**Opzione 3 - Installa in Applications:**
```bash
cp -r build/HandyShots.app ~/Applications/
open ~/Applications/HandyShots.app
```

---

## 🔍 Troubleshooting

### "Permission denied"
```bash
chmod +x scripts/*.sh
```

### "xcodebuild not found"
```bash
xcode-select --install
```

### "Cannot verify developer"
L'app usa una firma ad-hoc per sviluppo locale. Se macOS blocca l'apertura:
1. System Settings → Privacy & Security
2. Scorri fino a vedere "HandyShots was blocked"
3. Click "Open Anyway"

### Build fallisce con errori Swift
Assicurati di avere Xcode 15.0+ installato:
```bash
xcodebuild -version
```

### App non appare nella menu bar
Verifica che LSUIElement sia impostato correttamente in Info.plist. Riavvia l'app.

---

## 🗂️ Struttura File Generati

```
.
├── .build/                    # Output Swift Package Manager
│   └── release/
│       └── HandyShots        # Eseguibile compilato
│
└── build/                    # Output finale
    └── HandyShots.app/       # App bundle standalone
        └── Contents/
            ├── Info.plist
            ├── PkgInfo
            ├── MacOS/
            │   └── HandyShots    # Eseguibile firmato
            └── Resources/        # Assets e resources
```

---

## 🧪 Testing

Dopo il build, testa queste funzionalità:

- [ ] App appare nella menu bar con icona 📷
- [ ] Left click apre popover
- [ ] Right click apre menu (Settings/Quit)
- [ ] Prima apertura mostra welcome screen
- [ ] Selezione cartella funziona
- [ ] Settings window si apre
- [ ] Slider tempo funziona
- [ ] App si chiude correttamente da Quit

---

## 📝 Note

- **Clean Build**: Sempre consigliato usare `fresh-build.sh` per build di rilascio
- **Incremental Build**: Per sviluppo veloce usa solo `build.sh`
- **Permissions**: Gli script richiedono accesso a file system e database TCC
- **Code Signing**: Usa firma ad-hoc (`-`) per sviluppo locale
- **Universal Binary**: Tenta build per arm64 e x86_64 quando possibile

---

## 🆘 Supporto

Se incontri problemi:

1. Verifica prerequisiti (Xcode, Swift)
2. Esegui clean completo: `./scripts/clean.sh`
3. Controlla console Xcode per errori: `Console.app`
4. Verifica permessi: System Settings → Privacy & Security

---

**Buon sviluppo! 🚀**
