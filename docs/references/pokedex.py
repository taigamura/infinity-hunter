#!/usr/bin/env python3
"""Merge the per-gen tag files into pokedex_tags.json and provide a tag->anchor picker.
Anchors resolve to the dex-correct Gen4 battle sprite (Spr_4d_<dex>.png), which the
generator downscales to ~40px so it acts as a low-res icon anchor (won't over-detail)."""
import json, os, glob, sys

HERE=os.path.dirname(os.path.abspath(__file__))
SPRITES=os.path.join(HERE,"Gen 4 Pokemon")

def build():
    merged={}
    for g in ["tags_gen1.json","tags_gen2.json","tags_gen3.json","tags_gen4.json"]:
        with open(os.path.join(HERE,g)) as f: merged.update(json.load(f))
    # attach a resolved sprite path per dex (base form, or _m/_f fallback)
    for dex,e in merged.items():
        cands=[f"Spr_4d_{int(dex):03d}.png", f"Spr_4d_{int(dex):03d}_m.png", f"Spr_4d_{int(dex):03d}_f.png"]
        e["sprite"]=next((c for c in cands if os.path.exists(os.path.join(SPRITES,c))), None)
    out=os.path.join(HERE,"pokedex_tags.json")
    with open(out,"w") as f: json.dump(merged,f,indent=0)
    return merged

def load():
    p=os.path.join(HERE,"pokedex_tags.json")
    if not os.path.exists(p): return build()
    with open(p) as f: return json.load(f)

def find(db, *query, body=None, limit=12):
    """return dex entries whose tags (and optional body) contain ALL query tags."""
    q=set(t.lower() for t in query); res=[]
    for dex,e in db.items():
        tags=set(e["body"].split()+[t.lower() for t in e["t"]]) if False else set([e["b"].lower()]+[t.lower() for t in e["t"]])
        if body and e["b"]!=body: continue
        if q.issubset(tags): res.append((int(dex),e))
    res.sort()
    return res[:limit]

if __name__=="__main__":
    db=build()
    print(f"built pokedex_tags.json — {len(db)} entries\n")
    # demo queries
    demos=[("slime","ooze"),("slime","floating"),("dragon","2-arms","2-legs"),
           ("golem","2-arms"),("rock","golem"),("bird","wings"),("fish","aquatic"),
           ("round","big-eyes","cute"),("floating","ghost")]
    for q in demos:
        hits=find(db,*q,limit=8)
        names=", ".join(f"{e['n']}#{d}" for d,e in hits) or "(none)"
        print(f"[{' + '.join(q)}] -> {names}")
