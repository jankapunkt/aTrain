import zipfile
import os
from io import BytesIO
from flask import send_file, redirect
from .archive import TRANSCRIPT_DIR


# https://stackoverflow.com/questions/20646822/how-to-serve-static-files-in-flask
# https://stackoverflow.com/questions/53880816/how-do-i-zip-an-entire-folder-with-subfolders-and-serve-it-through-flask-witho


def download(file_name):
    file_path = os.path.join(TRANSCRIPT_DIR, file_name)
    file_path = os.path.join(file_path, 'transcription_maxqda.txt')
    print('download', file_path)

#    memory_file = BytesIO()
#    with zipfile.ZipFile(memory_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
#        for root, dirs, files in os.walk(file_path):
#            for file in files:
#                zipf.write(os.path.join(root, file))
#
#   memory_file.seek(0)
    try:
        return send_file(file_path, as_attachment=True)
    except:
        return redirect('/404')