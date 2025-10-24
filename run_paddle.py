import os, json
from paddleocr import PaddleOCR
from PIL import Image
import numpy as np
import argparse
import random


parser = argparse.ArgumentParser()
parser.add_argument("--sample-size", type=int, default=0)
parser.add_argument("--seed", type=int, default=0)
parser.add_argument("--dataset", type=str)
parser.add_argument("--run-dir", type=str)
parser.add_argument("--document-type", type=str)
parser.add_argument("--language-type", type=str)

args = parser.parse_args()

if args.dataset and args.document_type:
    img_folder = args.dataset + '/' + args.document_type
else:
    raise ValueError("Please provide a dataset path using --dataset and --document-type.")
results = []

all_images = [
    name for name in os.listdir(img_folder)
    if name.endswith(('.png', '.jpg', '.jpeg', '.tiff'))
]

if not all_images or len(all_images) == 0:
    raise ValueError("No images found in the specified folder.")

if args.sample_size > 0:
    rng = random.Random(args.seed)
    sample_count = min(args.sample_size, len(all_images))
    images = rng.sample(all_images, sample_count)
else:
    images = all_images

if args.language_type == 'eng':
    model_name = "PP-OCRv5_mobile_rec"
elif args.language_type == 'ara':
    model_name = "arabic_PP-OCRv3_mobile_rec"
    
ocr = PaddleOCR(text_recognition_model_name=model_name, use_textline_orientation=True, lang=args.language_type)
#ocr = PaddleOCR(use_textline_orientation=True, lang='ch') # For Chinese
#ocr = PaddleOCR(use_textline_orientation=True, lang='ar') # For Arabic

for img_name in images:
    img_path = os.path.join(img_folder, img_name)
    try:
        pil_img = Image.open(img_path).convert("RGB")
        img_np = np.array(pil_img)
        ocr_result = ocr.predict(img_np)
        text_lines = ocr_result[0]['rec_texts']  # This gets the list of recognized text strings
        results.append({'image': img_name, 'pred': "\n".join(text_lines)})
    except Exception as e:
        print("Error with", img_name, ":", e)
        # Save empty prediction if error occurs for robust batching
        results.append({'image': img_name, 'pred': ""})    

file_location = 'experiments/new_runner_experiment/' + args.run_dir + '/paddleocr_results.json'
print("Saving results to", file_location)
with open(file_location, 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print("Saved", len(results), "results")