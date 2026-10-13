## 1.1.0

- Histórico de quadros: com `historyFrames` o adapter captura a tela a cada `historyInterval`, guarda
  os últimos quadros sem codificar e, no erro, anexa todos (mais o do erro) como entries de screenshot.
- Cada quadro tem UUID (`screenshotId`), horário (`screenshotCapturedAt`), posição e momento
  (`history` ou `error`); cada captura registra a linha `Capturado quadro da tela - UUID <uuid>`.
- A mensagem da entry de screenshot passou de `Screenshot: <erro>` para
  `Quadro da tela anexado ao erro - UUID <uuid>`.

## 1.0.0

- Initial version.
