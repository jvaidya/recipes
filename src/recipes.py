#import xmltodict
import json

from config_vars import BASE_DIR, hostname

def read_records(filename):
    xmldict = xmltodict.parse(open(filename))
    records = xmldict['document']['Recipes']['records']
    count = xmldict['document']['Recipes']['count']
    return records

def write_json(filename, record):
    fh = open(filename,'w')
    json.dump(record, fh)
    fh.close()

def read_json_from_num(num):
    filename = "recipe_%s.json" % num
    return read_json(filename)

def read_json(filename):
    fh = open(filename)
    record = json.load(fh)
    fh.close()
    return record

def process_record(record):
    #print record['title']
    show_recipe(record)

def show_list(list=[]):
    if not list:
        list = read_json('recipe_list.json')
    url = 'http://10.1.10.10/recipes'
    print "<table BORDER=1>"
    for l in list:
        title = l['title']
        filename = l['filename']
        row = '<A HREF="%s?action=show&filename=%s">%s</A><BR>' % (url, filename, title)
        print_row(row)
    print "</table>\n";

def show_recipe(recipe):
    print "<H2>%s</H2><HR>\n" % recipe['title'];    

    print "<table BORDER=2 CELLSPACING=5>"
    print "<tr>"
    print "<td VALIGN=top>"

    print "<B>Ingredients:</B><BR>\n"
    cnt = 0
    print "<table CELLSPACING=10>"
    for i in recipe['ingredients']:
        cnt += 1
	if i['measure'] == "SectionHeading":
	    print "</table><BR>\n"
	    print "<B><I>%s</B></I><BR>\n" % i['comment']
	    print "<table CELLSPACING=10><BR>\n"
	    cnt = 0
        else:
            ic = i['ingredient']
            if i['comment'] and i['comment'] != 'NIL' and i['comment'] != 'None':
                ic += ", %s" % i['comment']
            print_row(i['amount'], i['measure'], ic)

    print "</table><BR>\n"

    print "</td>"
    print "<td VALIGN=top>"

    print "<B>Directions:</B><BR><BR>\n"
    cnt = 0
    print "<table CELLSPACING=10>"
    for i in recipe['directions']:
      cnt += 1
      print_row("%s." % cnt, i['text'])

    print "</table>"

    print "</td>"
    print "</tr>"
    print "</table>"

def print_row(*args):
    print "<tr>\n"
    for a in args:
        print "<td>%s</td>\n" % a
    print "</tr>\n"

def xml_to_json():
    records = read_records('Recipes.xml')
    num = 1
    list = []
    for r in records:
        filename = "recipe_%s.json" % num
        write_json(filename, r)
        m = {}
        m['title'] = r['title']
        m['filename'] = filename
        list.append(m)
        num += 1
    write_json("recipe_list.json",list)

    
if __name__ == '__main__':
    #xml_to_json()
    num = 1
    record = read_json_from_num(num)
    #process_record(record)
    list = read_json('recipe_list.json')
    show_list(list)

