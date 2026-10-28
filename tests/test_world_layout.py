"""Repeatable validation regression tests for world layout proposal v0.2."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/world'))
from validate_world import validate,point_sector,touched_sectors,reachable

DATA=json.loads((ROOT/'docs/world/world-layout.v0.2.json').read_text(encoding='utf-8'))

class WorldValidatorTests(unittest.TestCase):
    def setUp(self):self.world=copy.deepcopy(DATA)
    def test_baseline(self):
        v=validate(self.world);self.assertTrue(v['ok'],v['errors']);self.assertEqual(v['checks']['nodes'],28);self.assertEqual(v['checks']['paths'],30)
    def test_key_anchors_all_reviewed(self):
        owners={n['id']:n['owner_sector'] for n in self.world['nodes']}
        self.assertEqual([owners[i] for i in ['pillar_whole','pillar_fallen','pillar_broken','dry_road']],['S11','S12','S12','S13'])
    def test_all_nodes_explicit_owner_agrees_with_geometry(self):
        for n in self.world['nodes']:
            self.assertEqual(point_sector(n['grid'],self.world['sectors']),[n['owner_sector']],n['id'])
    def test_routes_sectors_geometrically_match(self):
        for p in self.world['paths']:
            self.assertEqual(touched_sectors(p['polyline'],self.world['sectors']),p['sectors_crossed'],p['id'])
    def test_duplicate_node_detected(self):
        self.world['nodes'][0]['id']=self.world['nodes'][1]['id'];self.assertFalse(validate(self.world)['ok'])
    def test_duplicate_path_detected(self):
        self.world['paths'][0]['id']=self.world['paths'][1]['id'];self.assertFalse(validate(self.world)['ok'])
    def test_unknown_path_endpoint_detected(self):
        self.world['paths'][0]['to_node']='does-not-exist';self.assertFalse(validate(self.world)['ok'])
    def test_unknown_flag_detected(self):
        self.world['paths'][0]['requires_flag']='nonsense';self.assertFalse(validate(self.world)['ok'])
    def test_offmap_node_detected(self):
        self.world['nodes'][0]['grid']=[-1,0];self.assertFalse(validate(self.world)['ok'])
    def test_offmap_road_detected(self):
        self.world['paths'][0]['polyline'].insert(1,[-1,1]);self.assertFalse(validate(self.world)['ok'])
    def test_wrong_owner_detected(self):
        self.world['nodes'][14]['owner_sector']='S12';self.assertFalse(validate(self.world)['ok'])
    def test_wrong_crossing_detected(self):
        self.world['paths'][10]['sectors_crossed']=['S01'];self.assertFalse(validate(self.world)['ok'])
    def test_mismatched_polyline_endpoint_detected(self):
        self.world['paths'][0]['polyline'][-1]=[10,10];self.assertFalse(validate(self.world)['ok'])
    def test_gate_removal_detected(self):
        for p in self.world['paths']:
            if p['id']=='stones__old_road':p.pop('requires_flag')
        self.assertFalse(validate(self.world)['ok'])
    def test_story_gates_explicit(self):
        before=reachable(self.world,set());after=reachable(self.world,{'dzwigacz_defeated','village_lamp_lit','guardian_defeated'})
        self.assertNotIn('chamber',before);self.assertNotIn('old_road',before);self.assertNotIn('dry_road',before)
        self.assertIn('chamber',after);self.assertIn('old_road',after);self.assertIn('dry_road',after)
    def test_middle_stage_guardian_still_gated(self):
        pre=reachable(self.world,{'dzwigacz_defeated'});self.assertIn('chamber',pre);self.assertNotIn('guardian',pre)

if __name__=='__main__':unittest.main()
