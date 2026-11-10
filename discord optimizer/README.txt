================================================================
           DISCORD SCREEN SHARE & STREAM OPTIMIZER
================================================================

Folder: c:\Users\Levy\Downloads\discord optimizer

Fisiere disponibile:
1. Rulare-Rapida.bat
   - Dai dublu-click pe el si face toata optimizarea automat in cateva secunde.
   - Recomandat: click-dreapta -> "Run as administrator" pentru a seta si prioritatea CPU mare.

2. Optimize-Discord.bat
   - Deschide un meniu interactiv unde poti alege:
     [1] Optimizare completa
     [2] Doar curatare cache & shadere GPU
     [3] Dezactivare accelerare hardware
     [4] Reactivare accelerare hardware
     [5] Ghid de setari

----------------------------------------------------------------
SETARI OBLIGATORII IN APLICATIA DISCORD (Voice & Video):
----------------------------------------------------------------
Dupa rularea scriptului, deschide Discord -> Setari (rotita stanga jos) -> Voce si Video (Voice & Video) -> deruleaza in jos la AVANSAT:

1. [OpenH264 Video Codec provided by Cisco Systems] -> ON (Activat)
2. [H.264 Hardware Acceleration]                    -> OFF (Dezactivat)
   (Pe placile integrate Intel HD Graphics, daca e activat, placa video ajunge la 100% si ecranul ingheata!)
3. [Use our latest technology to capture your screen] -> OFF (Dezactivat)
4. [Use an experimental method to capture audio]      -> OFF (Dezactivat)
5. [Quality of Service High Packet Priority]          -> OFF (Dezactivat)

Cand pornesti partajarea de ecran (Screen Share):
- Selecteaza 720p si 30 FPS.
- Selecteaza fereastra jocului/aplicatiei (Aplications), nu intregul monitor (Screens).
