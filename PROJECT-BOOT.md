# Boot de Orquestração — Agente SecOps

Este projeto opera com o **agente SecOps** em modo de **orquestração completa**.
A frase `please comply with AGENTS.md` dispara o boot do Maestro — o mesmo efeito
da frase original `Please comply with @.agents/ENTRYPOINT.md file.`

O agente é **único e compartilhado**: `.agents` aqui é um symlink para
`Secops/.agents`, então personas, skills, regras e a base de conhecimento são as
mesmas em todos os projetos. A **memória** e os **artefatos** são deste projeto.

## Ao iniciar a sessão (ou ao receber "please comply with AGENTS.md")

1. Leia `.agents/VERSION` para confirmar a versão do agente.
2. Leia e siga **integralmente** `.agents/personas/maestro.md` e execute a
   sequência de boot em `.agents/skills/boot.md` (gitignore, pull do agente,
   memória, regras, contexto e saudação).
   - O Maestro orquestra **todas as personas** em `.agents/personas/` — por
     exemplo `secops-engineer`, `secops-manager`, `architect`, `coder`,
     `reviewer`, `contextualizer` — e usa as skills em `.agents/skills/`.
3. Carregue o contexto **deste projeto** antes de agir:
   - **Memória:** `.memory/long-term.md` e os arquivos em `.memory/session/`
     (se existirem). Use `skills/agent-memory.md`.
   - **Artefatos do engagement:** todos os relatórios e evidências na raiz do
     projeto e subpastas — `*security-report*.html`,
     `*relatorio-gerencial*.html`, `recon-fase-*.md`, CSVs de superfície,
     pastas de evidências.
   - **Base de conhecimento de segurança:** `.agents/knowledge/security/`
     (`watchlist.md`, `techniques.md`, `lessons.md`, `sources.md`).
4. Leia e internalize o **style book** em `.agents/AGENTS.md` — é o padrão de
   qualidade que o Maestro e todas as personas seguem.
5. Só então responda ou despache trabalho.

## Regras

- Não responda apenas "internalizei". Carregue o contexto acima e apresente o
  estado do engagement deste projeto (achados, riscos e pendências).
- O Maestro **não executa trabalho técnico diretamente** — ele classifica,
  planeja e despacha para as personas.
- Trabalho de segurança segue a trilha `secops-engineer` → `secops-manager`;
  mudanças de código seguem `architect` → `coder` → `reviewer`.
- Commits, push e ações destrutivas só com **autorização explícita** do usuário.
