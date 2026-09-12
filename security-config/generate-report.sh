#!/bin/bash

OUTPUT="reports/security-report.html"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD=${BUILD_NUMBER:-"local"}

cat > $OUTPUT << 'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Sécurité — NodeGoat</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f6f9; color: #333; }

        .header {
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
            padding: 30px 40px;
            border-bottom: 4px solid #e94560;
        }
        .header h1 { font-size: 28px; margin-bottom: 8px; }
        .header .meta { font-size: 14px; opacity: 0.8; }

        .container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            border-top: 4px solid #ccc;
        }
        .summary-card.critical { border-top-color: #dc3545; }
        .summary-card.high     { border-top-color: #fd7e14; }
        .summary-card.medium   { border-top-color: #ffc107; }
        .summary-card.low      { border-top-color: #28a745; }
        .summary-card .number { font-size: 42px; font-weight: bold; margin: 8px 0; }
        .summary-card .label  { font-size: 13px; color: #666; text-transform: uppercase; letter-spacing: 1px; }
        .critical .number { color: #dc3545; }
        .high .number     { color: #fd7e14; }
        .medium .number   { color: #ffc107; }
        .low .number      { color: #28a745; }

        .section {
            background: white;
            border-radius: 10px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        .section h2 {
            font-size: 18px;
            margin-bottom: 16px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .tool-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        .badge-sast    { background: #6f42c1; }
        .badge-sca     { background: #0d6efd; }
        .badge-dast    { background: #e94560; }
        .badge-secrets { background: #fd7e14; }

        table { width: 100%; border-collapse: collapse; font-size: 14px; }
        th {
            background: #f8f9fa;
            padding: 12px 14px;
            text-align: left;
            font-weight: 600;
            color: #555;
            border-bottom: 2px solid #e9ecef;
        }
        td { padding: 11px 14px; border-bottom: 1px solid #f0f0f0; vertical-align: top; }
        tr:hover { background: #fafafa; }

        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        .badge-critical { background: #dc3545; }
        .badge-high     { background: #fd7e14; }
        .badge-medium   { background: #ffc107; color: #333; }
        .badge-low      { background: #28a745; }
        .badge-info     { background: #17a2b8; }

        .decision {
            padding: 20px 24px;
            border-radius: 10px;
            font-size: 18px;
            font-weight: bold;
            text-align: center;
            margin-bottom: 24px;
        }
        .decision.reject  { background: #fce8ea; border: 2px solid #dc3545; color: #dc3545; }
        .decision.warning { background: #fff3cd; border: 2px solid #ffc107; color: #856404; }
        .decision.accept  { background: #d4edda; border: 2px solid #28a745; color: #155724; }

        .tool-info { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .tool-card {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 16px;
            border-left: 4px solid #6f42c1;
        }
        .tool-card h4 { margin-bottom: 8px; font-size: 14px; }
        .tool-card p  { font-size: 13px; color: #666; line-height: 1.5; }

        .footer {
            text-align: center;
            padding: 20px;
            color: #999;
            font-size: 13px;
        }

        pre { background: #f8f9fa; padding: 12px; border-radius: 6px; font-size: 12px; overflow-x: auto; white-space: pre-wrap; word-break: break-all; }

        .status-ok   { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
    </style>
</head>
<body>

<div class="header">
    <h1>🔒 Rapport de Sécurité — OWASP NodeGoat</h1>
    <div class="meta">
        Généré le : DATE_PLACEHOLDER &nbsp;|&nbsp;
        Build Jenkins : #BUILD_PLACEHOLDER &nbsp;|&nbsp;
        Projet : Employee Retirement Savings Management
    </div>
</div>

<div class="container">

HTMLEOF

# Injecter la date et le build number
sed -i "s/DATE_PLACEHOLDER/$DATE/g" $OUTPUT
sed -i "s/BUILD_PLACEHOLDER/$BUILD/g" $OUTPUT

# ─── Compter les résultats npm audit ───
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

if [ -f reports/npm-audit.json ]; then
    CRITICAL_COUNT=$(python3 -c "
import json,sys
try:
    d=json.load(open('reports/npm-audit.json'))
    print(d.get('metadata',{}).get('vulnerabilities',{}).get('critical',0))
except: print(0)
" 2>/dev/null || echo 0)
    HIGH_COUNT=$(python3 -c "
import json,sys
try:
    d=json.load(open('reports/npm-audit.json'))
    print(d.get('metadata',{}).get('vulnerabilities',{}).get('high',0))
except: print(0)
" 2>/dev/null || echo 0)
    MEDIUM_COUNT=$(python3 -c "
import json,sys
try:
    d=json.load(open('reports/npm-audit.json'))
    print(d.get('metadata',{}).get('vulnerabilities',{}).get('moderate',0))
except: print(0)
" 2>/dev/null || echo 0)
    LOW_COUNT=$(python3 -c "
import json,sys
try:
    d=json.load(open('reports/npm-audit.json'))
    print(d.get('metadata',{}).get('vulnerabilities',{}).get('low',0))
except: print(0)
" 2>/dev/null || echo 0)
fi

# ─── Résumé visuel ───
cat >> $OUTPUT << HTMLEOF

    <!-- RÉSUMÉ -->
    <div class="summary-grid">
        <div class="summary-card critical">
            <div class="label">Critical</div>
            <div class="number">$CRITICAL_COUNT</div>
            <div class="label">Vulnérabilités</div>
        </div>
        <div class="summary-card high">
            <div class="label">High</div>
            <div class="number">$HIGH_COUNT</div>
            <div class="label">Vulnérabilités</div>
        </div>
        <div class="summary-card medium">
            <div class="label">Medium</div>
            <div class="number">$MEDIUM_COUNT</div>
            <div class="label">Vulnérabilités</div>
        </div>
        <div class="summary-card low">
            <div class="label">Low</div>
            <div class="number">$LOW_COUNT</div>
            <div class="label">Vulnérabilités</div>
        </div>
    </div>

HTMLEOF

# ─── Section Bearer (SAST + Secrets) ───
cat >> $OUTPUT << 'HTMLEOF'
    <!-- BEARER SAST -->
    <div class="section">
        <h2>🔍 Analyse Statique du Code Source (SAST + Secrets) <span class="tool-badge badge-sast">Bearer CLI</span></h2>
        <p style="margin-bottom:14px; color:#666; font-size:14px;">
            Bearer CLI analyse le code source à la recherche d'injections, de mauvaises pratiques
            cryptographiques, de secrets exposés et de violations OWASP Top 10.
        </p>
HTMLEOF

if [ -f reports/bearer-report.json ]; then
    BEARER_CRITICALS=$(python3 -c "
import json
try:
    d=json.load(open('reports/bearer-report.json'))
    findings=d.get('findings',[])
    c=[f for f in findings if f.get('severity','').lower()=='critical']
    print(len(c))
except: print('N/A')
" 2>/dev/null || echo "N/A")
    cat >> $OUTPUT << HTMLEOF
        <p><strong>Résultats Bearer :</strong> $BEARER_CRITICALS finding(s) critiques détectés.</p>
        <p style="margin-top:10px;font-size:13px;color:#666;">
            📎 Voir le rapport complet : <code>bearer-report.html</code> (archivé dans les artefacts Jenkins)
        </p>
HTMLEOF
else
    cat >> $OUTPUT << 'HTMLEOF'
        <p class="status-fail">⚠️ Rapport Bearer non trouvé. Vérifier l'étape SAST dans la console Jenkins.</p>
HTMLEOF
fi

echo "    </div>" >> $OUTPUT

# ─── Section npm audit (SCA) ───
cat >> $OUTPUT << 'HTMLEOF'
    <!-- SCA npm audit -->
    <div class="section">
        <h2>📦 Analyse des Dépendances (SCA) <span class="tool-badge badge-sca">npm audit</span></h2>
        <p style="margin-bottom:14px; color:#666; font-size:14px;">
            npm audit analyse les dépendances déclarées dans package.json et les compare
            à la base de vulnérabilités connues (CVE/NPM Advisory Database).
        </p>
        <table>
            <thead>
                <tr>
                    <th>Package</th>
                    <th>Sévérité</th>
                    <th>CVE / Advisory</th>
                    <th>Description</th>
                    <th>Correction</th>
                </tr>
            </thead>
            <tbody>
HTMLEOF

if [ -f reports/npm-audit.json ]; then
    python3 << 'PYEOF' >> $OUTPUT
import json

severity_badge = {
    "critical": "badge-critical",
    "high": "badge-high",
    "moderate": "badge-medium",
    "low": "badge-low",
    "info": "badge-info"
}

try:
    with open('reports/npm-audit.json') as f:
        data = json.load(f)

    vulns = data.get('vulnerabilities', {})
    if not vulns:
        advisories = data.get('advisories', {})
        rows = []
        for adv in advisories.values():
            sev = adv.get('severity', 'info')
            badge = severity_badge.get(sev, 'badge-info')
            name = adv.get('module_name', 'N/A')
            title = adv.get('title', 'N/A')[:80]
            url = adv.get('url', '#')
            fix = adv.get('recommendation', 'Mettre à jour')[:60]
            cve = ', '.join(adv.get('cves', [])) or 'N/A'
            rows.append(f'''<tr>
                <td><strong>{name}</strong></td>
                <td><span class="badge {badge}">{sev.upper()}</span></td>
                <td><a href="{url}" target="_blank">{cve}</a></td>
                <td>{title}</td>
                <td>{fix}</td>
            </tr>''')
        if rows:
            print('\n'.join(rows[:20]))
        else:
            print('<tr><td colspan="5" class="status-ok">✅ Aucune vulnérabilité détectée dans les dépendances</td></tr>')
    else:
        rows = []
        for pkg, details in list(vulns.items())[:20]:
            sev = details.get('severity', 'info')
            badge = severity_badge.get(sev, 'badge-info')
            fix = details.get('fixAvailable', False)
            fix_str = "✅ Mise à jour disponible" if fix else "⚠️ Correction manuelle requise"
            via = details.get('via', [])
            title = via[0].get('title', 'N/A') if via and isinstance(via[0], dict) else str(via[0]) if via else 'N/A'
            url = via[0].get('url', '#') if via and isinstance(via[0], dict) else '#'
            rows.append(f'''<tr>
                <td><strong>{pkg}</strong></td>
                <td><span class="badge {badge}">{sev.upper()}</span></td>
                <td><a href="{url}" target="_blank">Advisory</a></td>
                <td>{title[:80]}</td>
                <td>{fix_str}</td>
            </tr>''')
        if rows:
            print('\n'.join(rows))
        else:
            print('<tr><td colspan="5" class="status-ok">✅ Aucune vulnérabilité détectée dans les dépendances</td></tr>')
except Exception as e:
    print(f'<tr><td colspan="5">Erreur de lecture : {e}</td></tr>')
PYEOF
else
    echo '<tr><td colspan="5" class="status-fail">⚠️ Rapport npm audit non trouvé</td></tr>' >> $OUTPUT
fi

cat >> $OUTPUT << 'HTMLEOF'
            </tbody>
        </table>
    </div>

    <!-- DAST ZAP -->
    <div class="section">
        <h2>🌐 Analyse Dynamique (DAST) <span class="tool-badge badge-dast">OWASP ZAP</span></h2>
        <p style="margin-bottom:14px; color:#666; font-size:14px;">
            OWASP ZAP effectue un scan baseline sur l'application en cours d'exécution,
            testant les endpoints exposés pour détecter XSS réfléchi, headers manquants,
            configurations incorrectes et expositions non intentionnelles.
        </p>
        <p>
            📎 Rapport complet disponible : <code>zap-report.html</code> (archivé dans les artefacts Jenkins)
        </p>
    </div>

    <!-- Gitleaks -->
    <div class="section">
        <h2>🔐 Détection de Secrets <span class="tool-badge badge-secrets">Gitleaks</span></h2>
        <p style="margin-bottom:14px; color:#666; font-size:14px;">
            Gitleaks analyse le code source à la recherche de clés API, tokens, mots de passe
            et autres secrets exposés dans les fichiers du projet.
        </p>
        <table>
            <thead>
                <tr>
                    <th>Fichier</th>
                    <th>Type de secret</th>
                    <th>Ligne</th>
                    <th>Description</th>
                </tr>
            </thead>
            <tbody>
HTMLEOF

if [ -f reports/gitleaks-report.json ]; then
    python3 << 'PYEOF' >> $OUTPUT
import json
try:
    with open('reports/gitleaks-report.json') as f:
        content = f.read().strip()
    if not content or content == 'null':
        print('<tr><td colspan="4" class="status-ok">✅ Aucun secret détecté dans le code source</td></tr>')
    else:
        data = json.loads(content)
        if not data:
            print('<tr><td colspan="4" class="status-ok">✅ Aucun secret détecté dans le code source</td></tr>')
        else:
            for item in data[:15]:
                f = item.get('File', 'N/A')
                rule = item.get('RuleID', item.get('Description', 'N/A'))
                line = item.get('StartLine', 'N/A')
                desc = item.get('Secret', '')[:40] + '...' if item.get('Secret') else 'Voir rapport'
                print(f'<tr><td><code>{f}</code></td><td><span class="badge badge-high">{rule}</span></td><td>{line}</td><td>{desc}</td></tr>')
except Exception as e:
    print(f'<tr><td colspan="4">Erreur : {e}</td></tr>')
PYEOF
else
    echo '<tr><td colspan="4" class="status-fail">⚠️ Rapport Gitleaks non trouvé</td></tr>' >> $OUTPUT
fi

cat >> $OUTPUT << 'HTMLEOF'
            </tbody>
        </table>
    </div>

    <!-- Tableau récapitulatif des vulnérabilités identifiées manuellement -->
    <div class="section">
        <h2>📋 Tableau des Vulnérabilités Identifiées</h2>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Vulnérabilité</th>
                    <th>CWE</th>
                    <th>Sévérité</th>
                    <th>État</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>V1</td>
                    <td>IDOR — Allocations</td>
                    <td>CWE-639</td>
                    <td><span class="badge badge-high">HIGH</span></td>
                    <td class="status-ok">✅ Corrigé</td>
                    <td>req.session.userId utilisé</td>
                </tr>
                <tr>
                    <td>V2</td>
                    <td>XSS Stocké — Profil</td>
                    <td>CWE-79</td>
                    <td><span class="badge badge-high">HIGH</span></td>
                    <td class="status-fail">❌ Non corrigé</td>
                    <td>Correction requise avant déploiement</td>
                </tr>
                <tr>
                    <td>V3</td>
                    <td>Server-Side JS Injection — Contributions</td>
                    <td>CWE-95</td>
                    <td><span class="badge badge-critical">CRITICAL</span></td>
                    <td class="status-ok">✅ Corrigé</td>
                    <td>parseInt() remplace eval()</td>
                </tr>
                <tr>
                    <td>V4</td>
                    <td>Security Misconfiguration — Headers HTTP</td>
                    <td>CWE-16</td>
                    <td><span class="badge badge-medium">MEDIUM</span></td>
                    <td class="status-fail">❌ Non corrigé</td>
                    <td>Ajouter helmet.js</td>
                </tr>
                <tr>
                    <td>V5</td>
                    <td>Données sensibles — Mots de passe en clair</td>
                    <td>CWE-256</td>
                    <td><span class="badge badge-critical">CRITICAL</span></td>
                    <td class="status-fail">❌ Non corrigé</td>
                    <td>Activer bcrypt dans user-dao.js</td>
                </tr>
                <tr>
                    <td>V6</td>
                    <td>Missing Function Level Access Control — /benefits</td>
                    <td>CWE-862</td>
                    <td><span class="badge badge-critical">CRITICAL</span></td>
                    <td class="status-fail">❌ Non corrigé</td>
                    <td>Ajouter middleware isAdmin</td>
                </tr>
                <tr>
                    <td>V7</td>
                    <td>Unvalidated Redirect — /learn</td>
                    <td>CWE-601</td>
                    <td><span class="badge badge-medium">MEDIUM</span></td>
                    <td class="status-ok">✅ Corrigé</td>
                    <td>Liste blanche d'URLs autorisées</td>
                </tr>
            </tbody>
        </table>
    </div>

HTMLEOF

# ─── Décision de déploiement ───
cat >> $OUTPUT << 'HTMLEOF'
    <!-- DÉCISION -->
    <div class="decision reject">
        🔴 DÉCISION : REJECT DEPLOYMENT
        <p style="font-size:14px; font-weight:normal; margin-top:10px;">
            Des vulnérabilités critiques non corrigées (CWE-862, CWE-256, CWE-79) empêchent
            tout déploiement en production. Une nouvelle exécution du pipeline est requise
            après remédiation complète.
        </p>
    </div>

    <!-- OUTILS UTILISÉS -->
    <div class="section">
        <h2>🛠️ Outils Utilisés</h2>
        <div class="tool-info">
            <div class="tool-card" style="border-left-color:#6f42c1">
                <h4>🔍 Bearer CLI — SAST + Secret Detection</h4>
                <p>Analyse statique du code source. Détecte injections, mauvaises pratiques crypto,
                secrets exposés. <strong>Limite :</strong> ne voit pas le comportement runtime.</p>
            </div>
            <div class="tool-card" style="border-left-color:#0d6efd">
                <h4>📦 npm audit — SCA</h4>
                <p>Analyse des dépendances npm contre les CVE publiées.
                <strong>Limite :</strong> ne couvre que les vulnérabilités déjà répertoriées.</p>
            </div>
            <div class="tool-card" style="border-left-color:#e94560">
                <h4>🌐 OWASP ZAP — DAST</h4>
                <p>Scan dynamique de l'application en fonctionnement. Détecte XSS réfléchi,
                headers manquants. <strong>Limite :</strong> ne détecte pas les failles logiques (IDOR).</p>
            </div>
            <div class="tool-card" style="border-left-color:#fd7e14">
                <h4>🔐 Gitleaks — Secret Detection</h4>
                <p>Détecte clés API, tokens, mots de passe dans les fichiers source.
                <strong>Limite :</strong> peut générer des faux positifs.</p>
            </div>
        </div>
    </div>

</div>

<div class="footer">
    Rapport généré automatiquement par le pipeline CI/CD Jenkins &nbsp;|&nbsp;
    Examen Sécurité des Données — Licence 3 Cybersécurité
</div>

</body>
</html>
HTMLEOF

echo "✅ Rapport HTML généré : $OUTPUT"