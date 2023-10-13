# JPr_Projekt_Ada
projekt Ada, projekt Ada

Motyw jest taki, że produktami są modele pociągów, a klienci przychodzą kupować zestawy. Jako pracownicy musimy chodzić między magazynem a kasą

Główne zmiany wprowadzone względem programu startowego:
1. Zmiana działania bufora - pierwotnie bufor na zmianę przyjmował jeden produkt, obsługiwał jednego klienta itd. Gdy tego, którego oczekiwał, nie było, to na niego czekał.
   Teraz działa to tak, że w pętli przyjmuje produkty, jeśli przez kilka sekund nie przychodzą nowe opuszczamy pętlę i wchodzimy w pętlę obsługiwania klientów. Tam podobnie, obsługujemy ich, a    gdy przez kilka sekund ich nie ma, to zmieniamy na przyjmowanie produktów.
   Dodatkowo jest limit przyjętych produktów pod rząd i obsłużonych klientów pod rząd, żeby przez złe ustawienie liczb nie utknąć w magazynie lub przy kasie na wieczność.
2. Gdy klient przez kilka sekund nie zostanie obsłużony, to ze znudzenia zmieni zestaw, który chce kupić.

   Powyższe punkty realizują czasomierz z budzikiem, pierwszy w postaci:
       select
         accept entry
       or
         delay
         ...
       end select
   A drugi w postaci:
       select
         task.call
       or
         delay
         ...
       end select

3. Maksymalne ograniczenie na każdy produkt - liczymy ile razy każdy produkt pojawia się we wszystkich zestawach. Dzielimy to przez łączną liczbę produktów we wszystkich zestawach i mnożymy przez pojemność bufora. Otrzymany wynik jest zaokrąglany w górę, żeby zawsze bufor mógł być wykorzystany w pełni. Przy zwykłym zaokrąglaniu czasem mogłoby pozostawać puste miejsce (np. bufor o pojemności 25 podzielony równo na 3 produkty - 8,(3) zaokrągli się do 8 i tylko 24 będą używane).
4. Większa liczba produktów, klientów, zestawów
5. Usunąłem z konsumentów zmienną "Consumption", również usunąłem z entry Start "Consumption_Time", które jest jej przypisywane. Poza przypisaniem nic innego nie robiły. Nie wiem czemu tam były w ogóle. Analogiczna sytuacja dla producentów i ich "Production" i "Production_Time"
6. Ilość produktów, które mamy w posiadaniu nie jest wyświetlana po każdym przyjęciu produktu, ale po przejściu z magazynu do kasy. Natomiast wciąż po każdym kliencie wypisujemy stan posiadania.

Do zakleszczenia, o którym mówi instrukcja nie powinno nigdy dojść, nawet w startowym programie, bo już tam zaimplementowane jest pilnowanie, żeby zawsze było miejsce na każdy zestaw. Prawdziwym problemem, który tam był jest głodzenie, które powinno być teraz poprawione.

DO ZROBIENIA:
I    Posprawdzać czy na pewno działa i spełnia wymagania.
II   Dodać lub poprawić kilka komentarzy - w szczególności opis i podpisanie się na górze.
