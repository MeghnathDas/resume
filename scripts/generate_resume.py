#!/usr/bin/env python3
import json
import os
import re

def tex_escape(text):
    """
    :param text: a plain text message
    :return: the message escaped to appear correctly in LaTeX
    """
    if not isinstance(text, str):
        return text
    conv = {
        '&': r'\&', '%': r'\%', '$': r'\$', '#': r'\#', '_': r'\_',
        '{': r'\{', '}': r'\}', '~': r'\textasciitilde{}', '^': r'\^{}',
    }
    regex = re.compile('|'.join(re.escape(str(key)) for key in sorted(conv.keys(), key=lambda item: -len(item))))
    return regex.sub(lambda mo: conv[mo.group(0)], text)

def generate_tex():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    json_path = os.path.join(project_root, 'profile.datasource.json')
    tex_path = os.path.join(project_root, 'resume.tex')

    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {json_path} not found.")
        return

    content = []
    content.append(r"\documentclass[10pt]{article}")
    content.append(r"    \usepackage[english]{babel}")
    content.append(r"    \input{config/minimal-resume-config}")
    content.append(r"    \begin{document}")
    content.append("")
    content.append(r"\begin{center}")
    content.append("\t% Personal")
    content.append("\t% -----------------------------------------------------")
    content.append(f"\t{{\\fontsize{{\\sizeone}}{{\\sizeone}}\\fontspec[Path = fonts/,LetterSpace=15]{{Montserrat-Regular}} {data['name']}}}")
    content.append("\t\\\\")
    content.append("\t\\vspace{2mm}")
    personal_info = f"{data['email']} -- {data['phone']} -- {data['location']} -- {data['website']}"
    content.append(f"\t{{\\fontsize{{1em}}{{1em}}\\fontspec[Path = fonts/]{{Montserrat-Light}} {personal_info}}}")
    content.append(r"\end{center}")

    # Skills
    content.append("% Chapter: Skills")
    content.append("% ------------------------")
    content.append("")
    content.append(r"\chap{SKILLS}{")
    content.append("\t\\begin{newitemize}")
    for skill in data['skills']:
        content.append(f"\t\t\\item {tex_escape(skill['category'])}: {tex_escape(skill['items'])}")
    content.append("\t\\end{newitemize}")
    content.append("}")

    # Experience
    content.append("% Chapter: Work Experience")
    content.append("% ------------------------")
    content.append(r"\chap{EXPERIENCE}{")
    for job in data['experience']:
        content.append("\t")
        content.append("\t\\job")
        content.append(f"\t{{{tex_escape(job['company'])}}}")
        content.append(f"\t{{{tex_escape(job['period'])}}}")
        content.append(f"\t{{{tex_escape(job['role'])}}}")
        content.append(f"\t{{{tex_escape(job['location'])}}}")
        content.append("\t{\\begin{newitemize}")
        for highlight in job['highlights']:
            content.append(f"\t\t\\item {{{tex_escape(highlight)}}}")
        content.append("\t\t\\end{newitemize}}")
    content.append("}\n")

    # Projects
    content.append("% Chapter: Projects")
    content.append("% ------------------------")
    content.append("")
    content.append(r"\chap{PROJECTS}{")
    for project in data['projects']:
        content.append("\t")
        content.append("\t\\project")
        content.append(f"\t{{{tex_escape(project['name'])}}}")
        content.append("\t{}")
        content.append("\t{}")
        content.append(f"\t{{{tex_escape(project['details'])}}}")
    content.append("}\n")

    # Education
    content.append("% Chapter: Education")
    content.append("% ------------------")
    content.append("")
    content.append(r"\chap{EDUCATION}{")
    for edu in data['education']:
        content.append("\t")
        content.append("\t\\school")
        content.append(f"\t{{{tex_escape(edu['school'])}}}")
        content.append(f"\t{{{tex_escape(edu['period'])}}}")
        content.append(f"\t{{{tex_escape(edu['degree'])}}}")
        content.append(f"\t{{{tex_escape(edu['location'])}}}")
        content.append("\t{}")
    content.append("}")

    content.append("")
    content.append(r"\end{document}")

    with open(tex_path, 'w') as f:
        f.write("\n".join(content))
    print(f"Successfully generated {tex_path}")

if __name__ == "__main__":
    generate_tex()