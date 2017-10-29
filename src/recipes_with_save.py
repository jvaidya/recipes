import json
import os
import shutil
import time
import glob

from config_vars import BASE_DIR, hostname

RECIPE_DIR = os.path.join(BASE_DIR, 'data', 'rw')

def empty_ingredient():
    return dict(ord=1, amount=0, measure='t.', ingredient='Ingredient', comment='Comment')

def empty_directions():
    return dict(text="Add directions", ord=1)

def save_recipe(arguments, filename):
    recipe = arguments_to_recipe(arguments)
    write_json_with_backup(filename, recipe)
    save_title_in_list_if_changed(recipe['title'], filename)

def get_recipe_copy_filename(filename):
    return os.path.join(os.path.dirname(filename), 'recipe_created_at_%s.json' % int(time.time()))

def save_title_in_list_if_changed(new_title, filename):
    list_file = os.path.join(RECIPE_DIR, 'recipe_list.json')
    recipe_list = read_json(list_file)
    changed = False
    for l in recipe_list:
        if l['filename'] == os.path.basename(filename):
            if l['title'] != new_title:
                l['title'] = new_title
                changed = True
    if changed:
    	write_json_with_backup(list_file, recipe_list)

def delete_recipe(filename):
    # move the file to the removed directory
    os.system('mv %s %s' % (os.path.join(BASE_DIR, filename), os.path.join(RECIPE_DIR, 'removed')))
    # remove the entry from list
    list_file = os.path.join(RECIPE_DIR, 'recipe_list.json')
    recipe_list = read_json(list_file)
    delete_index = None
    for i, l in enumerate(recipe_list):
        if l['filename'] == os.path.basename(filename):
            delete_index = i
    if delete_index is not None:
        del recipe_list[delete_index]
    	write_json_with_backup(list_file, recipe_list)

def copy_recipe(filename):
    # copy recipe file
    new_filename = get_recipe_copy_filename(filename)
    os.system('cp %s %s' % (os.path.join(BASE_DIR, filename), os.path.join(BASE_DIR, new_filename)))
    # add copied recipe to the list file
    list_file = os.path.join(RECIPE_DIR, 'recipe_list.json')
    recipe_list = read_json(list_file)
    for l in recipe_list:
        if l['filename'] == os.path.basename(filename):
            new_title = 'Copy of ' + l['title']
    recipe_list.append(dict(filename=os.path.basename(new_filename), title=new_title))
    new_recipe = read_json(os.path.join(BASE_DIR, new_filename))
    new_recipe['title'] = new_title
    write_json(os.path.join(BASE_DIR, new_filename), new_recipe)
    write_json_with_backup(list_file, recipe_list)
    return new_filename

def arguments_to_recipe(arguments):
    def _clean(key):
        v = arguments.get(key, None)
        try:
            return v[0]
        except:
            return v or None
    def _clean_val(keystr, i):
	return _clean('%s_%s' % (keystr, i))

    recipe = {}
    recipe['title'] = _clean('recipe_title') or 'Default Title'
    recipe['count'] = arguments.get('Count', 760)
    recipe['row_count'] = arguments.get('row_count', 15)
    recipe['direction_row_count'] = arguments.get('direction_row_count', 15)
    recipe['ingredients'] = [] 
    recipe['directions'] = [] 
    row_count = int(_clean('row_count'))
    direction_row_count = int(_clean('direction_row_count'))
    rec_list = []
    # process ingredients
    for i in range(1, row_count + 1):
        rec = {}
        rec['ord'] = _clean_val('number', i) 
        if rec['ord'] is None:
           rec['ord'] = i 
	rec['measure'] = _clean_val('measure', i) 
        rec['amount'] = _clean_val('amount', i)
        rec['ingredient'] = _clean_val('ingredient', i)
        rec['comment'] = _clean_val('comment', i)
        rec_list.append(rec)
    for i in range(1, row_count + 1):
        for rec in reversed(rec_list):
            if i  == int(rec['ord']):
                recipe['ingredients'].append(rec)
    # process directions
    rec_list = []
    for i in range(1, direction_row_count + 1):
        rec = {}
        rec['ord'] = _clean_val('step', i) 
        if rec['ord'] is None:
           rec['ord'] = i 
        rec['text'] = _clean_val('text', i) 
        if rec['text'] is None:
           rec['text'] = 'Enter line here'
        rec_list.append(rec)
    for i in range(1, direction_row_count + 1):
        for rec in reversed(rec_list):
            if i  == int(rec['ord']):
                recipe['directions'].append(rec)
    return recipe


def write_json_with_backup(filename, record):
    shutil.copy(filename, get_next_filename(filename))
    write_json(filename, record)

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

def get_next_filename(filename):
    justname, ext = os.path.splitext(filename)
    vers = [0]
    for p in glob.glob('%s_version_*%s' % (justname, ext)):
        jn, ext = os.path.splitext(p)
        parts = jn.split('_')
        vers.append(int(parts[-1]))
    new_ver = max(vers) + 1 
    justname += '_version_%s' % new_ver 
    return justname + ext
