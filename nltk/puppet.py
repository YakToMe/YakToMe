import xml.etree.ElementTree as ET
from pathlib import Path

# make every group into its own file
# we should probably update flutter_svg to read zip files and load these
# in some special way?
# groups should be named according to a path semantic /group/group/group
# only groups with id's.
# how do we incorporate the necessary order of the layers?
# what flutter code do we generate?



ns = { 'svg': 'http://www.w3.org/2000/svg'}

no_display = []

def write_file(file,string):
    with open(file, 'wb') as fd:
        fd.write(string)
        
def process_group(x):
    if x.attrib.get("style","") == "display:none;":
        no_display.append(x)
    for child in x.findall('svg:g',ns):
        process_group(child)
        
def remove_everything(x):
    ch = x.getchildren()
    for i in ch:
        x.remove(i)
        
def parse_puppet(file):
    dir = Path(file).parent
    tree = ET.parse(file)
    parent_map = {c: p for p in tree.iter() for c in p}
    root = tree.getroot()
    
    for child in root.findall('svg:g',ns):
        process_group(child)
    for e in no_display:
        parent_map[e].remove(e)
    write_file(dir/"simple.svg", ET.tostring(root))
    remove_everything(root)
    for e in no_display:
        e.attrib["style"]=""
        root.append(e)
        write_file(dir / (e.attrib["id"]+".svg"),ET.tostring(root))
        root.remove(e)

    
   
parse_puppet("/myflutter/yak1/assets/puppet/fish.svg")
print("done")