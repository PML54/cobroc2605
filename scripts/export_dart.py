#!/usr/bin/env python3
"""
scripts/export_dart.py
Génère le contenu de historibroc.dart depuis la base SQLite.
Usage : python scripts/export_dart.py [--db PATH] [--out PATH]
"""

import sqlite3
import argparse
from datetime import datetime
from pathlib import Path

DEFAULT_DB  = Path(__file__).parent.parent / "db/historibroc.db"
DEFAULT_OUT = Path(__file__).parent.parent.parent / "cobroc/lib/historibroc.dart"


def _escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def _to_dmy(date_str: str) -> str:
    """Convertit AAAA-MM-JJ → JJ/MM/AAAA pour Flutter. Laisse intact si déjà JJ/MM/AAAA."""
    if len(date_str) == 10 and date_str[4] == "-" and date_str[7] == "-":
        return date_str[8:10] + "/" + date_str[5:7] + "/" + date_str[0:4]
    return date_str


def generate_dart(db_path: Path) -> str:
    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row
    rows = con.execute(
        "SELECT * FROM historic WHERE validated=1 ORDER BY id"
    ).fetchall()
    con.close()

    now = datetime.now().strftime("%y%m%d%H%M")
    n   = len(rows)

    lines = [
        "// lib/historibroc.dart",
        f"// Modified: {now}",
        "// Historic — liste des brocantes visitées",
        f"// CHANGEMENTS: (1) Export automatique depuis SQLite — {n} entrées validées",
        "",
        "import 'package:cobroc/diverspml.dart';",
        "import 'package:diacritic/diacritic.dart';",
        "",
        "class Historic {",
        '  String histName = "";',
        '  String histDate = "";',
        "  int histGood = 0;",
        '  String _histVille = "";',
        "  int histCodePostal = 0;",
        '  String histAdresse = "";',
        "  int histNbExpo = 0;",
        "  int histPmlDep = 0;",
        "  int histFraDep = 0;",
        "  int histMaisonDep = 0;",
        '  String histAvis = "";',
        '  String histDetail = "";',
        "  int histCode = 0;",
        "  DateTime histCheckDate = DateTime(2023, 07, 26);",
        '  String villeNormalized = "";',
        "",
        "  Historic(",
        "      this.histName,",
        "      this.histDate,",
        "      this.histGood,",
        "      String histVille,",
        "      this.histCodePostal,",
        "      this.histAdresse,",
        "      this.histNbExpo,",
        "      this.histPmlDep,",
        "      this.histFraDep,",
        "      this.histMaisonDep,",
        "      this.histAvis,",
        "      this.histDetail) {",
        "    BreakDate bri = BreakDate(histDate);",
        "    histCheckDate = bri.checkDate;",
        "    this.histVille =",
        "        histVille;",
        "  }",
        "",
        "  String get histVille => _histVille;",
        "",
        "  set histVille(String value) {",
        "    _histVille = value;",
        "    villeNormalized = normalizeString(value);",
        "  }",
        "",
        "  static String normalizeString(String str) {",
        "    String withoutDiacritics = removeDiacritics(str);",
        "    return withoutDiacritics.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');",
        "  }",
        "}",
        "",
        "final listHistoric = [",
    ]

    for row in rows:
        name    = _escape(row["hist_name"])
        date    = _escape(_to_dmy(row["hist_date"]))
        good    = row["hist_good"]
        ville   = _escape(row["hist_ville"])
        cp      = row["hist_code_postal"]
        adresse = _escape(row["hist_adresse"])
        expo    = row["hist_nb_expo"]
        pml     = row["hist_pml_dep"]
        fra     = row["hist_fra_dep"]
        maison  = row["hist_maison_dep"]
        avis    = _escape(row["hist_avis"])
        detail  = _escape(row["hist_detail"])

        lines.append(
            f'  Historic("{name}", "{date}", {good}, "{ville}", {cp}, '
            f'"{adresse}", {expo}, {pml}, {fra}, {maison}, "{avis}", "{detail}"),'
        )

    lines.append("];")
    lines.append("")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db",  default=str(DEFAULT_DB))
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    ap.add_argument("--print", action="store_true", help="Affiche sur stdout sans écrire")
    args = ap.parse_args()

    content = generate_dart(Path(args.db))

    if args.print:
        print(content)
        return

    out = Path(args.out)
    out.write_text(content, encoding="utf-8")
    n = content.count("Historic(")
    print(f"[OK] {n} entrées exportées vers {out}")


if __name__ == "__main__":
    main()
