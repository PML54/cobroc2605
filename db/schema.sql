CREATE TABLE IF NOT EXISTS historic (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  hist_name        TEXT    NOT NULL,
  hist_date        TEXT    NOT NULL,
  hist_good        INTEGER NOT NULL DEFAULT 0,
  hist_ville       TEXT    NOT NULL,
  hist_code_postal INTEGER NOT NULL DEFAULT 0,
  hist_adresse     TEXT    NOT NULL DEFAULT '',
  hist_nb_expo     INTEGER NOT NULL DEFAULT 0,
  hist_pml_dep     INTEGER NOT NULL DEFAULT 0,
  hist_fra_dep     INTEGER NOT NULL DEFAULT 0,
  hist_maison_dep  INTEGER NOT NULL DEFAULT 0,
  hist_avis        TEXT    NOT NULL DEFAULT '',
  hist_detail      TEXT    NOT NULL DEFAULT '',
  validated        INTEGER NOT NULL DEFAULT 0,
  agent_notes      TEXT    NOT NULL DEFAULT '',
  created_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_ville      ON historic(hist_ville);
CREATE INDEX IF NOT EXISTS idx_date       ON historic(hist_date);
CREATE INDEX IF NOT EXISTS idx_name       ON historic(hist_name);
CREATE INDEX IF NOT EXISTS idx_validated  ON historic(validated);
