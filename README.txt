Code Agent for PowerPC Mac (Tiger / 10.4)
============================================

HOW TO INSTALL
---------------------------------
1. Copy this whole folder onto your PowerPC Mac (USB stick, file sharing, etc.)

2. Double-click "Install.command".

3. A Terminal window opens. Choose Anthropic (Claude) or Gemini (Google) --
   Gemini has a free tier that needs no credit card at all. Then follow the
   prompts for that provider's API key (the installer explains how to get one).

4. When it says "Setup complete!", open a NEW Terminal window and type:

       code

That's it. No compiling, no MacPorts, no Xcode required.

REQUIREMENTS
------------------------
- A PowerPC Mac running Mac OS X 10.4 (Tiger) -- tested on an iBook G4
  (PowerBook6,5). Other PowerPC Macs on Tiger should work too, since the
  bundled curl was built without CPU-specific optimizations, but this
  hasn't been tested on every model. If "Install.command" reports that
  curl doesn't run on your machine, see the full project (README.md,
  build/ folder) to build it from source instead.

- Either an Anthropic API key (usage is billed separately, pay-as-you-go, at
  console.anthropic.com -- this is NOT the same as a claude.ai subscription)
  or a Gemini API key (free tier, no credit card needed, at
  aistudio.google.com/apikey). The installer asks which one you want.

WHAT'S INSIDE
-------------------------
- curl            : prebuilt, TLS 1.2/1.3-capable curl for PowerPC/Tiger
- cacert.pem       : current CA certificate bundle
- code-agent.pl    : the agent itself (single Perl file, no dependencies)
- Install.command  : the installer you double-click

More detail, and how to build everything from source, is in the full
project's README.md.
