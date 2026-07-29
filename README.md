# OpenDXP Coolify Deployment- & Betriebsanleitung

Dieses Repository enthält das Setup für den Betrieb der **OpenDXP-Plattform** (basierend auf dem Composer Skeleton) auf **Coolify**, parallel zu einem bestehenden Shopware-Stack auf demselben Server. Die gesamte Infrastruktur wird per **OpenTofu** deklarativ verwaltet, während Codeänderungen über eine automatisierte **GitHub Actions CI/CD-Pipeline** direkt ausgerollt werden.

---

## 1. Systemarchitektur & Besonderheiten

Um Ressourcenkonflikte auf einem gemeinsamen Server zu vermeiden, wurden folgende Anpassungen vorgenommen:
* **Datenbank**: Nutzt eine dedizierte MariaDB-Instanz, deren Zugangsdaten dynamisch über die Umgebungsvariable `DATABASE_URL` in die Container injiziert werden.
* **RabbitMQ & Queue-Konsum**: 
  * Der Management-Port der RabbitMQ-Instanz ist auf Host-Port **`25673`** konfiguriert (Port `25672` wird bereits von Shopware belegt).
  * Die Worker sind so konfiguriert, dass sie die spezifischen OpenDXP-Queues (`opendxp_core`, `opendxp_maintenance` etc.) statt standardmäßiger Shopware-Queues abarbeiten.
* **Scheduler**: Der Hintergrund-Scheduler nutzt den nativen Wartungsbefehl `opendxp:maintenance` (anstelle von `scheduled-task:run`).

---

## 2. Lokale Entwicklung (DDEV)

Für lokale Anpassungen steht ein DDEV-Setup zur Verfügung.

### Voraussetzungen
* DDEV lokal installiert.

### Lokale Umgebung starten
1. Navigieren Sie in das Verzeichnis:
   ```bash
   cd openDXP
   ```
2. Starten Sie DDEV:
   ```bash
   ddev start
   ```
3. Führen Sie den lokalen OpenDXP-Installer aus (erstellt die Tabellen und den lokalen Admin):
   ```bash
   ddev exec vendor/bin/opendxp-install
   ```

---

## 3. Infrastruktur-Provisionierung (OpenTofu)

Die Cloud-Infrastruktur auf Coolify wird vollautomatisch mittels OpenTofu verwaltet. Die Konfigurationsdateien liegen im Ordner `/infra` (bzw. `/openDXP/infra`).

### Konfiguration
1. **Secrets definieren (`infra/secrets.auto.tfvars`)**:
   Erstellen Sie die Datei aus dem Template und tragen Sie Ihre API-Tokens, Passwörter und Server-UUIDs ein:
   ```hcl
   coolify_token     = "Ihr-Coolify-API-Token"
   server_uuid       = "UUID-Ihres-Servers"
   # ...weitere S3- und DB-Passwörter...
   ```
2. **Umgebungseigenschaften (`infra/production.tfvars`)**:
   Passen Sie die Variablen an, z. B. Ihre Domänen, Bildquellen oder Speicherpfade.
   
### Bootstrap ausführen
Um die Datenbanken, Queues, Netzwerke und Services auf Coolify anzulegen:
```bash
cd openDXP
ddev coolify-bootstrap up production
```

---

## 4. Speicher-Konfiguration (Hetzner S3 & Flysystem)

In der Produktion werden hochgeladene Assets, Thumbnails und Dokumentenversionen nicht lokal gespeichert, sondern direkt auf **Hetzner S3 Object Storage** ausgelagert, um Datenverlust bei Container-Redeploys zu verhindern.

### Konfiguration der Bucket-Namen
Die Bucket-Namen werden in der Datei `infra/production.tfvars` unter dem Block `s3` definiert:
```hcl
  s3 = {
    bucket_private = "Ihr-Privater-Bucket-Name" # Für Versionen
    bucket_public  = "Ihr-Öffentlicher-Bucket-Name" # Für Assets & Thumbnails
    region         = "nbg1"
    endpoint       = "https://nbg1.your-objectstorage.com"
    cdn_domain     = "https://nbg1.your-objectstorage.com/Ihr-Public-Bucket/production/public"
    
    # Optionaler Ordner-Präfix in S3 (Default: "production/")
    path_prefix    = "Ihr-Projekt-Name/production" 
  }
```

### Funktionsweise in PHP
Unter `opendxp/config/packages/prod/flysystem.yaml` überschreibt Symfony die standardmäßigen lokalen Speicher-Adapter zur Laufzeit mit S3. 
* Lokale Uploads landen im Bucket unter `Ihr-Projekt-Name/production/public/`.
* Die Versionierungshistorie landet im privaten Bucket unter `Ihr-Projekt-Name/production/private/`.

---

## 5. Deployment-Pipeline (CI/CD)

Sobald Sie Änderungen am Code im Unterordner `/opendxp` vornehmen und ins Git-Repository pushen:
1. Trigger des GitHub Actions Workflows (`.github/workflows/opendxp-ci-cd.yml`).
2. Der Code wird kompiliert, Abhängigkeiten werden per Composer installiert und ein produktionsbereites Docker-Image wird gebaut.
3. Das Image wird verschlüsselt an die GitHub Container Registry (GHCR) übertragen (`ghcr.io/waesler/388_opendxp_coolify/opendxp:latest`).

### Änderungen deployen:
Sobald der GitHub-Build grün ist:
* Gehen Sie in Ihr **Coolify-Dashboard**.
* Öffnen Sie den Service **`web`**.
* Klicken Sie auf **Redeploy** (bzw. **Restart**). 
* Coolify zieht das neueste Image und startet den Container neu.

---

## 6. Automatisierter Container-Startup (Self-Healing)

Um manuelle administrative Schritte nach dem Deployen zu minimieren, verfügt das Docker-Image über ein intelligentes Startskript (`opendxp/.docker/entrypoint.sh`), das bei jedem Container-Boot automatisch ausgeführt wird:

1. **Datenbankverbindung prüfen**: Es wartet kurz auf die Verfügbarkeit der MariaDB-Datenbank.
2. **Auto-Installation**: Es prüft, ob die Datenbank bereits Tabellen enthält. Ist sie leer (z. B. nach dem ersten Aufsetzen oder Löschen der Container), führt das Skript automatisch die Core-Installation (`opendxp-install`) aus.
3. **Bundle-Installation**: Es installiert automatisch alle registrierten OpenDXP-Zusatzbundles (wie `OpenDxpSeoBundle`, `OpenDxpGlossaryBundle` etc.) und erzeugt deren Datenbanktabellen.
4. **Rechtekorrektur**: Es setzt die Dateiberechtigungen von `/var/www/html/var` und `/var/www/html/public/var` rekursiv auf den Webserver-User `www-data`, um Runtime-500-Fehler zu verhindern.
5. **App starten**: Startet `supervisord`, welcher PHP-FPM und Nginx parallel ausführt.

---

## 7. Troubleshooting

* **Fehler 500 im Browser**:
  Prüfen Sie, ob Berechtigungen blockieren oder Datenbanktabellen fehlen. Verbinden Sie sich per SSH/Coolify-Konsole auf den `web`-Container und prüfen Sie die Nginx- und Symfony-Fehlerprotokolle:
  ```bash
  cat /var/log/nginx/error.log
  tail -n 100 var/log/prod-error.log
  ```
* **Scheduler-Fehlermeldungen**:
  Sollte der Scheduler oder die Konsumenten keine Verbindung aufbauen können, vergewissern Sie sich, dass der Bootstrap-Prozess fehlerfrei durchgelaufen ist und die Services im selben Docker-Netzwerk laufen.
