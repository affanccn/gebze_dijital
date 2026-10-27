@echo off
chcp 65001 > nul
title Gebze Belediyesi Haber Canlı Senkronizasyonu
echo ============================================================
echo   GEBZE BELEDİYESİ - CANLI HABER SENKRONİZASYONU
echo ============================================================
echo.
echo Belediye web sitesindeki en guncel haberler taranıyor...
echo.

node scripts\news-sync\live-sync.mjs

echo.
echo ============================================================
echo İslem tamamlandi! Pencereyi kapatabilirsiniz.
echo ============================================================
pause
