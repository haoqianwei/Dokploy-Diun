import unittest
from unittest.mock import patch, MagicMock
import os
import json
import yaml
import sys

# Add src directory to path so we can import sync.py
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))
import sync

class TestSync(unittest.TestCase):
    def setUp(self):
        # Create a temp directory for files
        if not os.path.exists("/tmp/diun_test"):
            os.makedirs("/tmp/diun_test")
        
        # Override paths in sync.py for testing
        sync.os.environ["DOKPLOY_TOKEN"] = "test-token"
        sync.DOKPLOY_URL = "http://mock-dokploy"
        
        # We need to monkey-patch the file paths in sync.py or use a helper
        self.patch_paths()

    def patch_paths(self):
        # We'll wrap the open calls or just change the constants if we had them
        # For now, let's just make sure we capture what it writes
        pass

    @patch('sync.requests.get')
    def test_fetch_and_generate(self, mock_get):
        # Mock response from Dokploy
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {
                "name": "Project 1",
                "environments": [
                    {
                        "name": "Production",
                        "applications": [
                            {
                                "name": "App 1",
                                "sourceType": "docker",
                                "dockerImage": "nginx",
                                "applicationId": "app-id-1"
                            }
                        ]
                    }
                ]
            }
        ]
        mock_get.return_value = mock_response

        # Use local paths for testing
        with patch('builtins.open', unittest.mock.mock_open()) as mocked_file:
            apps = sync.fetch_dokploy_apps()
            self.assertEqual(apps[0]["id"], "app-id-1")
            self.assertEqual(apps[0]["name"], "App 1")
            
            sync.generate_diun_config(apps)
            
            # Verify normalize_image works
            self.assertEqual(apps[0]["image"], "docker.io/nginx:latest")
            
            # Verify generate_diun_config logic
            # This is a bit tricky with mock_open, but we can verify calls
            self.assertTrue(mocked_file.called)

if __name__ == "__main__":
    unittest.main()
