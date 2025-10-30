# HandyShots MVP - Specifiche Tecniche per Sviluppatore

## 📋 Panoramica del Progetto

**Nome:** HandyShots MVP  
**Piattaforma:** macOS  
**Framework:** SwiftUI + AppKit  
**Linguaggio:** Swift  
**Tipo:** Menu Bar Application (non finestra principale)  

---

## 🎯 Obiettivo del MVP

Creare un'applicazione menu bar che monitora la cartella screenshot di macOS e permette configurazione base. Questa è la versione minima per validare il concept prima di aggiungere funzionalità avanzate.

---

## ⚙️ Requisiti Tecnici

### **Ambiente di Sviluppo**
- Xcode 15.0+
- macOS 13.0+ (target deployment)
- Swift 5.5+
- SwiftUI 4.0+

### **Permissions & Capabilities**
- App Sandbox enabled
- User Selected File (Read Only) access
- Outgoing Connections (Client) per future funzionalità

---

## 🏗️ Architettura dell'Applicazione

```
HandyShots MVP
├── App Entry Point (HandyShotsApp.swift)
├── AppDelegate (Menu Bar Management)
├── Main Interface (PopoverView)
├── Settings Window (SettingsView)
├── System Integration (FolderDetector)
└── Data Persistence (UserDefaults)
```

---

## 📱 Funzionalità Richieste

### **1. Menu Bar Application**
- **Requisito:** Icona persistent nella menu bar di macOS
- **Implementazione:**
  - Usare `NSStatusBar.system.statusItem()`
  - Icona: SF Symbol `camera.fill`
  - Non mostrare finestra principale (solo Settings)
  - App deve rimanere attiva anche quando non è in focus

### **2. Click Gestione**
- **Left Click:** Apre popover principale
- **Right Click:** Apre context menu con opzioni:
  - "Settings" → Apre finestra impostazioni
  - "Quit" → Termina l'applicazione

### **3. Settings Window**
- **Accesso:** Click destro → Settings
- **Contenuto:**
  - Slider per tempo di visualizzazione screenshot (5-60 minuti)
  - Label che mostra valore corrente
  - Auto-save delle preferenze
- **Persistenza:** Usare `@AppStorage` o `UserDefaults`

### **4. Rilevamento Cartella Screenshot**
- **Metodo Primario:** Leggere preferenze sistema `com.apple.screencapture.location`
- **Metodo Fallback:** Desktop utente (`~/Desktop`)
- **Implementazione:**
  ```swift
  CFPreferencesCopyAppValue("location", "com.apple.screencapture")
  ```

### **5. Monitor Cambi Cartella**
- **Frequenza:** Polling ogni 3-5 secondi
- **Trigger:** Timer che controlla se preferenze sistema sono cambiate
- **Azione:** Aggiorna path interno e notifica UI se necessario

### **6. Popover Interface - Prima Apertura**
- **Condizione:** `isFirstLaunch = true` (salvato in UserDefaults)
- **UI Elements:**
  - Welcome message
  - Display cartella rilevata automaticamente
  - Bottone "Usa questa cartella"
  - Bottone "Scegli altra cartella" (apre NSOpenPanel)
- **Azione:** Dopo selezione, imposta `isFirstLaunch = false`

### **7. Popover Interface - Utilizzi Successivi**
- **Condizione:** `isFirstLaunch = false`
- **UI Elements:**
  - Header con titolo app
  - Display cartella attualmente monitorata
  - Bottone "Cambia Cartella" (corner/sidebar)
  - Placeholder area per future funzionalità screenshot
- **Dimensioni:** 400x300 pt

---

## 🗂️ File Structure

```
HandyShots/
├── HandyShotsApp.swift          // App entry point + AppDelegate
├── Views/
│   ├── PopoverView.swift        // Main popover interface
│   ├── WelcomeView.swift        // First launch welcome screen
│   └── SettingsView.swift       // Settings window
├── Utilities/
│   ├── FolderDetector.swift     // System screenshot folder detection
│   └── FolderMonitor.swift      // Folder change monitoring
└── Resources/
    └── Info.plist               // Bundle configuration
```

---

## 💾 Data Persistence Requirements

Usare `UserDefaults` per salvare:

| Key | Type | Default | Descrizione |
|-----|------|---------|-------------|
| `screenshotFolder` | String | "" | Path cartella screenshot selezionata |
| `isFirstLaunch` | Bool | true | Flag primo avvio |
| `timeFilter` | Int | 10 | Minuti per filtro temporale |

---

## 🎨 UI/UX Specifications

### **Visual Design**
- **Style:** macOS native design system
- **Colors:** System colors (adattamento automatico light/dark mode)
- **Typography:** System font stack
- **Icons:** SF Symbols 4.0

### **Popover Specifications**
- **Dimensioni:** 400x300 points
- **Behavior:** `.transient` (chiude quando click fuori)
- **Position:** Sotto l'icona menu bar
- **Animation:** Default system animations

### **Settings Window**
- **Dimensioni:** 400x250 points
- **Style:** Standard window (titolo + close button)
- **Modal:** No (può rimanere aperta)

---

## 🔧 Implementazione Dettagliata

### **AppDelegate Setup**
```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar icon
        // Configure popover
        // Start folder monitoring
    }
}
```

### **Folder Detection Logic**
```swift
static func detectSystemFolder() -> String? {
    // 1. Try com.apple.screencapture.location
    // 2. Fallback to ~/Desktop
    // 3. Return standardized path
}
```

### **Polling Implementation**
```swift
Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    // Check if system folder changed
    // Update internal state
    // Notify UI if needed
}
```

---

## 🚦 Testing Requirements

### **Manual Testing Checklist**
- [ ] App appare nella menu bar dopo launch
- [ ] Left click apre popover
- [ ] Right click apre context menu
- [ ] Prima apertura mostra welcome screen
- [ ] Selezione cartella funziona correttamente
- [ ] Settings window si apre e salva preferenze
- [ ] Slider tempo funziona (5-60 minuti)
- [ ] Monitor rileva cambi cartella sistema
- [ ] App non crasha quando si chiude popover
- [ ] App termina correttamente da Quit menu

### **Edge Cases**
- [ ] Cartella screenshot non accessibile
- [ ] Preferenze sistema corrotte
- [ ] Multiple instances dell'app
- [ ] System folder permission denied

---

## 📦 Deployment Requirements

### **Bundle Configuration**
- **Bundle ID:** `com.yourcompany.handyshots`
- **Version:** 1.0.0 (MVP)
- **Minimum macOS:** 13.0
- **Architecture:** Universal (Intel + Apple Silicon)

### **Code Signing**
- Development team configurato
- App Sandbox abilitato
- Notarization ready (per distribuzione)

---

## 🔄 Future Iterations (Non MVP)

Queste funzionalità NON sono richieste per il MVP ma sono previste per versioni successive:

- Screenshot thumbnails display
- Quick Look integration
- Drag & drop support
- OCR text recognition
- Screenshot annotation
- Cloud sync
- Hotkey shortcuts
- Advanced filtering options

---

## 📋 Deliverables

### **Code Deliverables**
1. Xcode project completo e compilabile
2. Codice commentato e documentato
3. README con istruzioni setup/build

### **Documentation**
1. Technical documentation inline
2. User guide per testing
3. Known issues/limitations document

### **Testing**
1. Tested su almeno macOS 13.0 e 14.0
2. Test report con screenshot delle funzionalità
3. Performance notes (memory usage, CPU impact)

---

## ⏱️ Stima Tempi di Sviluppo

| Componente | Ore Stimate |
|------------|-------------|
| Project setup + AppDelegate | 4-6 ore |
| UI Implementation (Popover + Settings) | 8-10 ore |
| Folder detection & monitoring | 6-8 ore |
| Data persistence & preferences | 3-4 ore |
| Testing & bug fixes | 4-6 ore |
| Documentation | 2-3 ore |
| **TOTALE** | **27-37 ore** |

---

## 🆘 Support & Questions

Per domande tecniche o chiarimenti durante lo sviluppo, fornire:
1. Screenshot dell'issue
2. Console logs relevant
3. Steps to reproduce
4. macOS version e Xcode version

---

*Documento creato il 26 Ottobre 2025 - HandyShots MVP v1.0*