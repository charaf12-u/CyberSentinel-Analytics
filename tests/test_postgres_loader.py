import json
import unittest

import pandas as pd

from ingestion.postgres_loader import normalize_dataframe


class NormalizeDataframeTests(unittest.TestCase):
    def normalize(self, frame, table="authentication_logs"):
        return normalize_dataframe(
            frame,
            source_file=f"{table}.csv",
            source_path=f"pc1/logs/{table}.csv",
            source_sha256="a" * 64,
            table_name=table,
        )

    def test_new_schema_keeps_unknown_fields_in_json(self):
        result = self.normalize(pd.DataFrame([{
            "timestamp_utc": "2026-07-23T10:00:00Z", "event_id": "4624",
            "hostname": "PC1", "risk_score": 75,
        }]))
        self.assertEqual(result.loc[0, "timestamp_raw"], "2026-07-23T10:00:00Z")
        self.assertEqual(result.loc[0, "event_id"], 4624)
        self.assertEqual(json.loads(result.loc[0, "extra_data"]), {
            "hostname": "PC1", "risk_score": 75,
        })

    def test_usb_aliases_use_typed_columns(self):
        result = self.normalize(
            pd.DataFrame([{"vendor_id": "1234", "product_id": "5678"}]),
            "usb_devices",
        )
        self.assertEqual(result.loc[0, "usb_vid"], "1234")
        self.assertEqual(result.loc[0, "usb_pid"], "5678")

    def test_alias_collision_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "collide"):
            self.normalize(pd.DataFrame([{"timestamp": "old", "timestamp_utc": "new"}]))


if __name__ == "__main__":
    unittest.main()
