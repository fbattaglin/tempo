# 🎵 Tempo

**Um metrônomo nativo pra macOS que não implica com sua CPU nem com seu ouvido.**

Sem Electron, sem framework web escondido debaixo do capô, sem 200MB pra
tocar um clique. Só SwiftUI + `AVAudioEngine`, um pêndulo que balança
*exatamente* no tempo do áudio (porque os dois nascem do mesmo relógio), e
uma interface que cabe na palma da mão — literalmente, é uma janelinha.

---

## ✨ O que ele faz

- 🎯 **BPM de 30 a 240**, com slider, campo numérico, ↑/↓ no teclado ou
  arrastando o peso do pêndulo (igual metrônomo mecânico de verdade: peso
  perto do eixo = rápido, longe = devagar).
- 🕰️ **Pêndulo sincronizado ao áudio de verdade** — não é dois timers
  separados torcendo pra ficarem alinhados. Ambos leem o mesmo relógio de
  sample-time, então nunca dessincronizam, nem depois de tocar por horas.
- 👆 **Tap tempo** — bata no ritmo (botão ou tecla `T`) que ele calcula o BPM.
- 🎼 **Compassos** de 2/4 a 12/8, com acento sonoro no primeiro tempo.
- ⚙️ **BPM padrão configurável** (⌘,) — chegou de um jeito, quer voltar pra
  ele com um clique ou `⌘0`? Você decide qual é esse número, não eu.
- 📊 **Menu bar** — dá pra rodar sem nem abrir a janela principal.
- 🌗 Dark mode, light mode, atalhos de teclado nativos — tudo do jeito que
  um app de macOS de verdade deveria se comportar.

## 🧠 Por que o timing não desanda

A cilada clássica de metrônomo em software: usar um `Timer` pra disparar
cada clique. Timers têm jitter, acumulam atraso, e depois de alguns minutos
o "clique" já não bate mais com o "tique". Aqui não rola isso — o motor de
áudio **agenda os cliques com precisão de amostra** direto no
`AVAudioEngine`, num acumulador de ponto flutuante que nunca deixa o
arredondamento virar bola de neve. Tem até teste automatizado garantindo
isso (veja `TempoTests/BeatClockTests.swift`).

## 🚀 Rodando o projeto

Precisa de Xcode 15+ e [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`) — o `.xcodeproj` não fica versionado, é gerado a
partir do `project.yml`.

### Jeito mais fácil: instalar direto

```sh
./install.sh
```

Builda tudo (universal, arm64 + x86_64), assina e já deixa instalado em
`/Applications`, substituindo a versão anterior. Abre o app sozinho no
final. Sem dmg, sem arrastar ícone.

Pra conferir se você está mesmo na build mais recente: **menu Tempo → About
Tempo**. Cada build carimba um número tipo `20260705.211212` (data + hora)
— bate com o que o script imprimiu? Você tá na versão certa.

### Só pra abrir no Xcode e mexer no código

```sh
xcodegen generate
open Tempo.xcodeproj
```
⌘R e pronto.

### Testes

```sh
xcodebuild -project Tempo.xcodeproj -scheme Tempo -configuration Debug -destination 'platform=macOS' test
```

### Gerar um `.dmg` de verdade (pra distribuir)

```sh
Packaging/build_dmg.sh
```

O app é assinado **ad-hoc** (sem conta Apple Developer paga). Se alguém
instalar via `.dmg` baixado, o Gatekeeper vai reclamar de "desenvolvedor não
identificado" na primeira abertura — clique direito no ícone → **Abrir** →
confirma. Só acontece uma vez.

## 🗺️ Arquitetura, por trás das cortinas

| Arquivo | O que faz |
|---|---|
| `Tempo/Audio/MetronomeEngine.swift` | O coração: agenda cliques sample-accurate no `AVAudioEngine`, nunca para o motor entre pausas (só o player), pra retomar ser instantâneo. |
| `Tempo/Audio/BeatClock.swift` | A única fonte da verdade sobre "quando é agora" — traduz sample-time de áudio pra host-time, pra UI ler sem tocar na thread de áudio. |
| `Tempo/Views/PendulumView.swift` | O pêndulo. Interpola entre as duas últimas batidas publicadas pelo `BeatClock` — zero lógica de tempo própria. |
| `Tempo/ViewModel/MetronomeViewModel.swift` | Estado observável: BPM, compasso, play/pause, tap tempo, tudo persistido. |
| `Tempo/Views/SettingsView.swift` | A telinha de preferências (⌘,) onde você define seu BPM padrão. |

## ⌨️ Atalhos

| Atalho | Ação |
|---|---|
| `Espaço` | Tocar / Pausar |
| `↑` / `↓` | BPM ±1 |
| `⇧↑` / `⇧↓` | BPM ±5 |
| `⌘0` | Restaurar BPM padrão |
| `⌘,` | Preferências |
| `T` (ou botão TAP) | Tap tempo |

---

*Feito pra ser leve, rápido e ficar fora do seu caminho — o metrônomo é o
acompanhante, não o protagonista.*
