import os
import requests
from langchain_community.vectorstores import FAISS
from langchain_openai.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, Docx2txtLoader
from firebase_admin import storage, firestore, credentials
from langchain_openai import ChatOpenAI
from langchain.prompts import PromptTemplate
import firebase_admin
import uuid
import time
from openai import AsyncOpenAI
import json
from test2 import extract_from_pdf

# Initialize Firestore for "aischool"
creds_aischool = credentials.Certificate(
    "aischool-ba7c6-firebase-adminsdk-n8tjs-59b0bf7672.json"
)
app_aischool = firebase_admin.initialize_app(
    creds_aischool, {"storageBucket": "aischool-ba7c6.appspot.com"}, name="aischool_app"
)  # Named to avoid conflicts

# Firestore & Storage for "aischool"
bucket = storage.bucket(app=app_aischool)
db_aischool = firestore.client(app=app_aischool)  # Primary Firestore (aischool)


# Initialize Firestore for "pees"
creds_pees = credentials.Certificate(
    "serviceAccountKey.json"
)  # Path to pees service account key
app_pees = firebase_admin.initialize_app(
    creds_pees, name="pees_app"
)  # Named to avoid conflicts
db_pees = firestore.client(app=app_pees)  # Secondary Firestore (pees)


# OpenAI API Key
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')

client = AsyncOpenAI(api_key=OPENAI_API_KEY)


def check_index_in_bucket(curriculum_id):
    """Check if FAISS index exists in Firebase Storage"""
    blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss")
    return blob.exists()


def download_index_from_bucket(curriculum_id):
    """Download FAISS index from Firebase Storage"""
    if not os.path.exists(f"faiss_index_{curriculum_id}"):
        os.makedirs(f"faiss_index_{curriculum_id}")

    faiss_blob = bucket.blob(
        f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss"
    )
    faiss_blob.download_to_filename(f"faiss_index_{curriculum_id}/index.faiss")

    pkl_blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.pkl")
    pkl_blob.download_to_filename(f"faiss_index_{curriculum_id}/index.pkl")


def upload_index_to_bucket(curriculum_id):
    """Upload FAISS index to Firebase Storage"""
    faiss_blob = bucket.blob(
        f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss"
    )
    faiss_blob.upload_from_filename(f"faiss_index_{curriculum_id}/index.faiss")

    pkl_blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.pkl")
    pkl_blob.upload_from_filename(f"faiss_index_{curriculum_id}/index.pkl")


def download_file(url, curriculum_id):
    """Download the curriculum file from a URL"""
    file_extension = url.split(".")[-1]
    file_path = f"curriculum_{curriculum_id}.{file_extension}"

    response = requests.get(url)
    with open(file_path, "wb") as f:
        f.write(response.content)

    return file_path


def vector_embedding(curriculum_id, file_url):
    """Load or create FAISS vector embeddings from curriculum documents"""
    embeddings = OpenAIEmbeddings(api_key=OPENAI_API_KEY)

    if check_index_in_bucket(curriculum_id):
        print("Loading FAISS index from Firebase Storage...")
        download_index_from_bucket(curriculum_id)
        vectors = FAISS.load_local(
            f"faiss_index_{curriculum_id}",
            embeddings,
            allow_dangerous_deserialization=True,
        )
    else:
        print("Creating FAISS index...")
        file_path = download_file(file_url, curriculum_id)
        file_extension = file_path.split(".")[-1]

        # Load the document based on file type
        if file_extension == "pdf":
            loader = PyPDFLoader(file_path)
        elif file_extension == "docx":
            loader = Docx2txtLoader(file_path)
        else:
            raise ValueError("Unsupported file type. Only PDF and DOCX are allowed.")

        docs = loader.load()

        # Split document into smaller chunks for vector embedding
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=10000, chunk_overlap=1500
        )
        final_documents = text_splitter.split_documents(docs)

        # Convert documents to FAISS vectors
        vectors = FAISS.from_documents(final_documents, embeddings)

        # Save FAISS index locally and upload to Firebase
        vectors.save_local(f"faiss_index_{curriculum_id}")
        upload_index_to_bucket(curriculum_id)

        # Remove downloaded file to free space
        os.remove(file_path)

    return vectors


async def retrieve_relevant_text(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 5, "max_length": 900})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


async def retrieve_relevant_text1(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 1, "max_length": 100})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


async def retrieve_relevant_text2(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 10, "max_length": 2000})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


import shutil


def delete_local_faiss_index(curriculum_id):
    local_dir = f"faiss_index_{curriculum_id}"
    if os.path.exists(local_dir):
        shutil.rmtree(local_dir)  # Deletes the directory and all its contents


def get_student_grade(student_id):
    student_doc = db_pees.collection("students").document(student_id).get()
    student_data = student_doc.to_dict()
    grades_map = student_data.get("assignedGrades", {}).get("grades", {})

    # Assuming there's only one key like "GRADE 12"
    for grade_name in grades_map.keys():
        return grade_name

    return ""


# async def generate_teaching_plan(
#     student_id,
#     curriculum_id,
#     curriculumname,
#     image_url,
#     language,
#     temp_pdf_path,
#     openai_client,
#     subject,
#     curriculum_coverage,
#     teacher_id,
#     # file,
#     saveInTeachingPlans=False,
# ):
#     """Generate a customized teaching plan using AsyncOpenAI and store it in Firestore."""

#     query = f""" find relevant context from curriculum text using given curriculum coverage topics:- {curriculum_coverage}"""
#     # Retrieve relevant text
#     relevant_text = await retrieve_relevant_text(curriculum_id, query)
#     # extracted_text1 = "\n\n".join(extracted_text)

#     # Check if the student exists in Firestore
#     student_ref = db_pees.collection("students").document(student_id)
#     student_doc = student_ref.get()

#     if student_doc.exists:
#         student_data = student_doc.to_dict()
#         student_name = (
#             student_data.get("profileInfo", {})
#             .get("personalInformation", {})
#             .get("name", "")
#         )
#     else:
#         student_name = ""

#     print("????????????????????", student_name, "????????????????????")

#     student_grade = get_student_grade(student_id)

#     evaluation_report = await extract_from_pdf(
#         temp_pdf_path,
#         openai_client,
#         curriculum_id,
#         subject,
#         curriculum_coverage,
#         language,
#     )

#     # Define system and user messages for the OpenAI completion request
#     messages = [
#         {
#             "role": "system",
#             "content": "You are an AI tutor creating a customized teaching plan based on curriculum data and student performance analysis STRICTLY CHECK LANGUAGE CONDITION OF RELEVANT TEXT ARABIC AND ENGLISH ONE.",
#         },
#         {
#             "role": "user",
#             "content": f"""
#             **Student Name is :- {student_name}**
#         Based on the extracted curriculum text, retrieved relevant information, and analyzed student performance, generate a structured teaching plan that is The plan should clearly highlight identified areas where improvements are required based on the analysis of the exams in JSON format.  

#         The AI should assess student answers from the provided exam image and compare them against the curriculum. It should identify individual student strengths and weaknesses and accumulate this knowledge over time to track their progress. The generated teaching plan should incorporate these insights to help teachers create targeted learning strategies.  


#         --- Retrieved Relevant Text ---
#         {relevant_text}

#         ***Ensure Generated Teaching Plan Must be In Same Langauge as relevant Text have
#         For Example If curriculum Relevant text have langauge of Arabic then full teaching plan Output Generate in Arabic if teaching plan is in english then generate teaching Plan in English.

#         Don't Change Field name of Json Output : assessmentMethods, instructionalStrategies, learningObjectives, recommendedResources,timeline This Must be same structure and Name But Data inside is in language condition of arabic and english ensure *Langauge* is the strict requirement HERE.***


#         ***The plan should be comprehensive and addressing all aspects of the student performance with very clear instructions and action plan Ensure Every Description Generated is of 3 Paragraph Atleast with personalization as Student Name.***

#         ***The plan should clearly highlight identified areas where improvements are required based on the analysis of Exam Evaluation Report (Having Correct and Wrong Answer Based on Curriculum Exam) :-  {evaluation_report}***

#         --- JSON Output Format ---
#         {{
#           "assessmentMethods": {{
#             "method1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "method2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "instructionalStrategies": {{
#             "strategy1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "strategy2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "learningObjectives": {{
#             "objective1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "objective2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "recommendedResources": {{
#             "resource1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "resource2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "timeline": {{
#             "week1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "week2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }}
#         }}
#         """,
#         },
#     ]

#     # Send request to OpenAI's GPT model asynchronously
#     response = await openai_client.chat.completions.create(
#         model="gpt-4.1-mini-2025-04-14",
#         messages=messages,
#         response_format={"type": "json_object"},
#         stream=False,
#     )

#     if response and response.choices:
#         try:
#             # Extract response and parse JSON
#             if saveInTeachingPlans:
#                 teaching_plan_json = json.loads(
#                     response.choices[0].message.content.strip()
#                 )

#                 # Generate a unique plan ID
#                 plan_id = str(uuid.uuid4()).replace("-", "_")

#                 teaching_plan_json["planId"] = plan_id

#                 if not student_doc.exists:
#                     return {"error": f"Student with ID {student_id} not found"}

#                 # Store the structured JSON teaching plan in Firestore
#                 student_ref.update(
#                     {
#                         f"teachingPlans.{plan_id}": {
#                             "actionPlan": teaching_plan_json,
#                             "createdAt": time.strftime(
#                                 "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                             ),
#                         }
#                     }
#                 )

#                 # Create a document ID using student_id and subject_id
#                 teaching_plan_doc_id = f"{student_id}"

#                 # Reference to the new TeachingPlans collection
#                 teaching_plan_ref = db_pees.collection("TeachingPlans").document(
#                     teaching_plan_doc_id
#                 )

#                 # Store the structured JSON teaching plan in the TeachingPlans collection
#                 # Update ONLY the specific subject inside the document, preserving other subjects
#                 teaching_plan_ref.set(
#                     {
#                         "subjects": {
#                             subject: {
#                                 "studentId": student_id,
#                                 "subjectId": subject,
#                                 "actionPlan": teaching_plan_json,
#                                 "teacher_id": teacher_id,
#                                 "createdAt": time.strftime(
#                                     "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                                 ),
#                             }
#                         }
#                     },
#                     merge=True,  # ?? Ensures only the given subject is updated, keeping other subjects intact
#                 )

#                 # evaluation_report = await evaluate_exam_script_with_groq(
#                 #     extracted_text,
#                 #     relevant_text=relevant_text,
#                 #     image_url=image_url,
#                 #     language=language,
#                 # )

#                 student_ref.update({"evaluation": evaluation_report})

#                 print(
#                     "\n? **Teaching Plan Stored in Firestore as JSON!**\n",
#                     teaching_plan_json,
#                 )
#                 delete_local_faiss_index(curriculum_id)

#                 return teaching_plan_json, evaluation_report, plan_id
#             else:
#                 teaching_plan_json, evaluation_report, plan_id = (
#                     "",
#                     evaluation_report,
#                     "",
#                 )
#                 student_ref.update({"evaluation": evaluation_report})
#                 return teaching_plan_json, evaluation_report, plan_id

#         except json.JSONDecodeError:
#             return {
#                 "error": "Failed to parse teaching plan response. AI did not return valid JSON."
#             }
#     else:
#         return {"error": "No valid teaching plan generated."}

# async def generate_teaching_plan(
#     student_id,
#     curriculum_id,
#     curriculumname,
#     image_url,
#     language,
#     temp_pdf_path,
#     openai_client,
#     subject,
#     curriculum_coverage,
#     teacher_id,
#     # file,
#     saveInTeachingPlans=False,
# ):
#     """Generate a customized teaching plan using AsyncOpenAI and store it in Firestore."""

#     query = f""" find relevant context from curriculum text using given curriculum coverage topics:- {curriculum_coverage}"""
#     # Retrieve relevant text
#     relevant_text = await retrieve_relevant_text(curriculum_id, query)
#     # extracted_text1 = "\n\n".join(extracted_text)

#     # Check if the student exists in Firestore
#     student_ref = db_pees.collection("students").document(student_id)
#     student_doc = student_ref.get()

#     if student_doc.exists:
#         student_data = student_doc.to_dict()
#         student_name = (
#             student_data.get("profileInfo", {})
#             .get("personalInformation", {})
#             .get("name", "")
#         )
#     else:
#         student_name = ""

#     print("????????????????????", student_name, "????????????????????")

#     student_grade = get_student_grade(student_id)

#     evaluation_report = await extract_from_pdf(
#         temp_pdf_path,
#         openai_client,
#         curriculum_id,
#         subject,
#         curriculum_coverage,
#         language,
#     )

#     # Define system and user messages for the OpenAI completion request
#     messages = [
#         {
#             "role": "system",
#             "content": "You are an AI tutor creating a customized teaching plan based on curriculum data and student performance analysis STRICTLY CHECK LANGUAGE CONDITION OF RELEVANT TEXT ARABIC AND ENGLISH ONE.",
#         },
#         {
#             "role": "user",
#             "content": f"""
#             **Student Name is :- {student_name}**
#         Based on the extracted curriculum text, retrieved relevant information, and analyzed student performance, generate a structured teaching plan that is The plan should clearly highlight identified areas where improvements are required based on the analysis of the exams in JSON format.  

#         The AI should assess student answers from the provided exam image and compare them against the curriculum. It should identify individual student strengths and weaknesses and accumulate this knowledge over time to track their progress. The generated teaching plan should incorporate these insights to help teachers create targeted learning strategies.  


#         --- Retrieved Relevant Text ---
#         {relevant_text}

#         ***Ensure Generated Teaching Plan Must be In Same Langauge as relevant Text have
#         For Example If curriculum Relevant text have langauge of Arabic then full teaching plan Output Generate in Arabic if teaching plan is in english then generate teaching Plan in English.

#         Don't Change Field name of Json Output : assessmentMethods, instructionalStrategies, learningObjectives, recommendedResources,timeline This Must be same structure and Name But Data inside is in language condition of arabic and english ensure *Langauge* is the strict requirement HERE.***


#         ***The plan should be comprehensive and addressing all aspects of the student performance with very clear instructions and action plan Ensure Every Description Generated is of 3 Paragraph Atleast with personalization as Student Name.***

#         ***The plan should clearly highlight identified areas where improvements are required based on the analysis of Exam Evaluation Report (Having Correct and Wrong Answer Based on Curriculum Exam) :-  {evaluation_report}***

#         --- JSON Output Format ---
#         {{
#           "assessmentMethods": {{
#             "method1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "method2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "instructionalStrategies": {{
#             "strategy1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "strategy2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "learningObjectives": {{
#             "objective1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "objective2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "recommendedResources": {{
#             "resource1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "resource2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "timeline": {{
#             "week1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "week2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }}
#         }}
#         """,
#         },
#     ]

#     # Send request to OpenAI's GPT model asynchronously
#     response = await openai_client.chat.completions.create(
#         model="gpt-4.1-mini-2025-04-14",
#         messages=messages,
#         response_format={"type": "json_object"},
#         stream=False,
#     )

#     if response and response.choices:
#         try:
#             # Extract response and parse JSON
#             if saveInTeachingPlans:
#                 teaching_plan_json = json.loads(
#                     response.choices[0].message.content.strip()
#                 )

#                 # Generate a unique plan ID
#                 plan_id = str(uuid.uuid4()).replace("-", "_")

#                 teaching_plan_json["planId"] = plan_id

#                 if not student_doc.exists:
#                     return {"error": f"Student with ID {student_id} not found"}

#                 # Store the structured JSON teaching plan in Firestore
#                 student_ref.update(
#                     {
#                         f"teachingPlans.{plan_id}": {
#                             "actionPlan": teaching_plan_json,
#                             "createdAt": time.strftime(
#                                 "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                             ),
#                         }
#                     }
#                 )

#                 # Create a document ID using student_id and subject_id
#                 teaching_plan_doc_id = f"{student_id}"

#                 # Reference to the new TeachingPlans collection
#                 teaching_plan_ref = db_pees.collection("TeachingPlans").document(
#                     teaching_plan_doc_id
#                 )

#                 # Store the structured JSON teaching plan in the TeachingPlans collection
#                 # Update ONLY the specific subject inside the document, preserving other subjects
#                 teaching_plan_ref.set(
#                     {
#                         "subjects": {
#                             subject: {
#                                 "studentId": student_id,
#                                 "subjectId": subject,
#                                 "actionPlan": teaching_plan_json,
#                                 "teacher_id": teacher_id,
#                                 "createdAt": time.strftime(
#                                     "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                                 ),
#                             }
#                         }
#                     },
#                     merge=True,  # ?? Ensures only the given subject is updated, keeping other subjects intact
#                 )

#                 # evaluation_report = await evaluate_exam_script_with_groq(
#                 #     extracted_text,
#                 #     relevant_text=relevant_text,
#                 #     image_url=image_url,
#                 #     language=language,
#                 # )

#                 student_ref.update({"evaluation": evaluation_report})

#                 print(
#                     "\n? **Teaching Plan Stored in Firestore as JSON!**\n",
#                     teaching_plan_json,
#                 )
#                 delete_local_faiss_index(curriculum_id)

#                 return teaching_plan_json, evaluation_report, plan_id
#             else:
#                 teaching_plan_json, evaluation_report, plan_id = (
#                     "",
#                     evaluation_report,
#                     "",
#                 )
#                 student_ref.update({"evaluation": evaluation_report})
#                 return teaching_plan_json, evaluation_report, plan_id

#         except json.JSONDecodeError:
#             return {
#                 "error": "Failed to parse teaching plan response. AI did not return valid JSON."
#             }
#     else:
#         return {"error": "No valid teaching plan generated."}

import os
import requests
# ... other imports from teachingplans.py (assuming them to be present)
from firebase_admin import storage, firestore, credentials
from openai import AsyncOpenAI
import json
import uuid # Essential for plan_id generation
import time # Essential for timestamp generation

# Placeholder imports/definitions for context since the full file isn't available
# These should exist in your actual teachingplans.py or app.py
# db_pees = firestore.client(name="pees_app") # Assuming initialized db client
async def retrieve_relevant_text(curriculum_id, query): return "Placeholder text for curriculum."
def get_student_grade(student_id): return "Grade 5"
async def extract_from_pdf(temp_pdf_path, openai_client, curriculum_id, subject, curriculum_coverage, language): return "Placeholder Evaluation Report."
def delete_local_faiss_index(curriculum_id): pass
# End of placeholders

# async def generate_teaching_plan(
#     student_id,
#     curriculum_id,
#     curriculumname,
#     image_url,
#     language,
#     temp_pdf_path,
#     openai_client,
#     subject,
#     curriculum_coverage,
#     teacher_id,
#     # file,
#     saveInTeachingPlans=False,
# ):
#     print("--- RUNNING FUNCTION AT LINE 642 ---")
#     # ... rest of function ...
#     """Generate a customized teaching plan using AsyncOpenAI and store it in Firestore."""

#     query = f""" find relevant context from curriculum text using given curriculum coverage topics:- {curriculum_coverage}"""
#     # Retrieve relevant text
#     relevant_text = await retrieve_relevant_text(curriculum_id, query)
#     # extracted_text1 = "\n\n".join(extracted_text)

#     # Check if the student exists in Firestore
#     student_ref = db_pees.collection("students").document(student_id)
#     student_doc = student_ref.get()

#     if student_doc.exists:
#         student_data = student_doc.to_dict()
#         student_name = (
#             student_data.get("profileInfo", {})
#             .get("personalInformation", {})
#             .get("name", "")
#         )
#     else:
#         student_name = ""

#     print("????????????????????", student_name, "????????????????????")

#     student_grade = get_student_grade(student_id)

#     evaluation_report = await extract_from_pdf(
#         temp_pdf_path,
#         openai_client,
#         curriculum_id,
#         subject,
#         curriculum_coverage,
#         language,
#     )

#     # Define system and user messages for the OpenAI completion request
#     messages = [
#         {
#             "role": "system",
#             "content": "You are an AI tutor creating a customized teaching plan based on curriculum data and student performance analysis STRICTLY CHECK LANGUAGE CONDITION OF RELEVANT TEXT ARABIC AND ENGLISH ONE.",
#         },
#         {
#             "role": "user",
#             "content": f"""
#             **Student Name is :- {student_name}**
#         Based on the extracted curriculum text, retrieved relevant information, and analyzed student performance, generate a structured teaching plan that is The plan should clearly highlight identified areas where improvements are required based on the analysis of the exams in JSON format. 

#         The AI should assess student answers from the provided exam image and compare them against the curriculum. It should identify individual student strengths and weaknesses and accumulate this knowledge over time to track their progress. The generated teaching plan should incorporate these insights to help teachers create targeted learning strategies. 

#         --- Retrieved Relevant Text ---
#         {relevant_text}

#         ***Ensure Generated Teaching Plan Must be In Same Langauge as relevant Text have
#         For Example If curriculum Relevant text have langauge of Arabic then full teaching plan Output Generate in Arabic if teaching plan is in english then generate teaching Plan in English.

#         Don't Change Field name of Json Output : assessmentMethods, instructionalStrategies, learningObjectives, recommendedResources,timeline This Must be same structure and Name But Data inside is in language condition of arabic and english ensure *Langauge* is the strict requirement HERE.***


#         ***The plan should be comprehensive and addressing all aspects of the student performance with very clear instructions and action plan Ensure Every Description Generated is of 3 Paragraph Atleast with personalization as Student Name.***

#         ***The plan should clearly highlight identified areas where improvements are required based on the analysis of Exam Evaluation Report (Having Correct and Wrong Answer Based on Curriculum Exam) :-  {evaluation_report}***

#         --- JSON Output Format ---
#         {{
#           "assessmentMethods": {{
#             "method1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "method2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "instructionalStrategies": {{
#             "strategy1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "strategy2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "learningObjectives": {{
#             "objective1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "objective2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "recommendedResources": {{
#             "resource1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "resource2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "timeline": {{
#             "week1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "week2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }}
#         }}
#         """,
#         },
#     ]

#     # Send request to OpenAI's GPT model asynchronously
#     response = await openai_client.chat.completions.create(
#         model="gpt-4.1-mini-2025-04-14",
#         messages=messages,
#         response_format={"type": "json_object"},
#         stream=False,
#     )

#     if response and response.choices:
#         try:
#             # Extract response and parse JSON
#             # This is the raw LLM output: {"assessmentMethods": {...}, ...}
#             raw_plan_data = json.loads(
#                 response.choices[0].message.content.strip()
#             )

#             # --- START MODIFICATION FOR NESTED STRUCTURE ---
            
#             # Generate a unique plan ID and inject it into the raw data
#             plan_id = str(uuid.uuid4()).replace("-", "_")
#             raw_plan_data["planId"] = plan_id

#             # Create the necessary nested structure for the API response and saving
#             # This ensures the returned data includes the "actionPlan" key
#             teaching_plan_data = {
#                 "actionPlan": raw_plan_data
#             }
            
#             # --- END MODIFICATION ---

#             if saveInTeachingPlans:
#                 if not student_doc.exists:
#                     return {"error": f"Student with ID {student_id} not found"}

#                 # Store the structured JSON teaching plan in Firestore (students collection)
#                 # Note: using teaching_plan_data which contains the {"actionPlan": ...} structure
#                 student_ref.update(
#                     {
#                         f"teachingPlans.{plan_id}": {
#                             "actionPlan": teaching_plan_data["actionPlan"], # Use the raw_plan_data here, as it's already structured correctly for this field
#                             "createdAt": time.strftime(
#                                 "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                             ),
#                         }
#                     }
#                 )

#                 # Create a document ID using student_id (consistent with existing logic)
#                 teaching_plan_doc_id = f"{student_id}"

#                 # Reference to the new TeachingPlans collection
#                 teaching_plan_ref = db_pees.collection("TeachingPlans").document(
#                     teaching_plan_doc_id
#                 )

#                 # Store the structured JSON teaching plan in the TeachingPlans collection
#                 # Update ONLY the specific subject inside the document, preserving other subjects
#                 teaching_plan_ref.set(
#                     {
#                         "subjects": {
#                             subject: {
#                                 "studentId": student_id,
#                                 "subjectId": subject,
#                                 "actionPlan": teaching_plan_data["actionPlan"], # Use the raw_plan_data here
#                                 "teacher_id": teacher_id,
#                                 "createdAt": time.strftime(
#                                     "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                                 ),
#                             }
#                         }
#                     },
#                     merge=True,  # Ensures only the given subject is updated, keeping other subjects intact
#                 )

#                 student_ref.update({"evaluation": evaluation_report})

#                 print(
#                     "\n? **Teaching Plan Stored in Firestore as JSON!**\n",
#                     teaching_plan_data,
#                 )
#                 delete_local_faiss_index(curriculum_id)

#                 # Return the structured plan data
#                 return teaching_plan_data, evaluation_report, plan_id
#             else:
#                 # If not saving, still return the structured plan data
#                 teaching_plan_data, evaluation_report, plan_id = (
#                     teaching_plan_data, # Return the structured plan data
#                     evaluation_report,
#                     plan_id,
#                 )
#                 student_ref.update({"evaluation": evaluation_report})
#                 return teaching_plan_data, evaluation_report, plan_id

#         except json.JSONDecodeError:
#             return {
#                 "error": "Failed to parse teaching plan response. AI did not return valid JSON."
#             }
#     else:
#         return {"error": "No valid teaching plan generated."}


# from flask import jsonify

# async def get_curriculum_list(teacher_id=None):
#     """
#     Retrieve curriculum IDs, names, grades, and subjects (Asynchronous).
#     If teacher_id is provided, filter by assigned grades & subjects
#     using efficient multiple Firestore queries.
#     """
#     curriculum_ref = db_aischool.collection("curriculum")
#     filtered_curriculum = [] # Initialize list for the results

#     if teacher_id:
#         # 1. Fetch teacher's assigned grades & subjects
#         teacher_ref = db_pees.collection("users").document(teacher_id)
        
#         # NOTE: In a *real* async environment with an async firestore client,
#         # you would 'await' this. The standard 'google-cloud-firestore'
#         # client's .get() is synchronous. This hybrid setup might be
#         # part of the complexity in your app.py.
#         # For now, we assume .get() is synchronous as before.
#         teacher_doc = teacher_ref.get() 

#         if not teacher_doc.exists:
#             # The function needs to return a Flask response object here.
#             return jsonify({"error": f"Teacher ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
#         assigned_grades = teacher_data.get("assignedGrades", {})

#         # 2. Flatten assigned grades & subjects into a set of (grade, subject) tuples
#         teacher_grade_subjects = set()
#         for grade, classes in assigned_grades.items():
#             grade_str = str(grade) 
#             for class_name, subjects in classes.items():
#                 for subject in subjects:
#                     # e.g., ("GRADE 1", "Math") or ("GRADE 1", "اللغة العربية")
#                     teacher_grade_subjects.add((grade_str, subject))

#         # 3. Perform a separate, efficient database query for each assigned pair
#         for grade, subject in teacher_grade_subjects:
#             # Create a query filtered by the specific grade AND subject
#             query = (
#                 curriculum_ref
#                 .where("grade", "==", grade)
#                 .where("subject", "==", subject)
#             )
            
#             # .stream() is also synchronous in the standard client.
#             docs = query.stream()
            
#             # Append the results from this query
#             for doc in docs:
#                 # Use doc.id to get the document ID (curriculum_id)
#                 filtered_curriculum.append({
#                     "curriculum_id": doc.id,
#                     "curriculum_name": doc.get("curriculum_name"),
#                     "grade": doc.get("grade"),
#                     "subject": doc.get("subject"),
#                 })

#     else:
#         # Fetch ALL curriculums if no teacher filter
#         docs = curriculum_ref.stream() # Synchronous call
#         filtered_curriculum = [
#             {
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": doc.get("subject"),
#             }
#             for doc in docs
#         ]

#     return jsonify({"curriculum": filtered_curriculum}), 200


# async def get_curriculum_list(teacher_id=None):
#     """
#     Retrieve curriculum IDs, names, grades, and subjects.
#     If teacher_id is provided, filter by assigned grades & subjects.
#     """
#     curriculum_ref = db_aischool.collection("curriculum")

#     if teacher_id:
#         # Fetch teacher's assigned grades & subjects
#         teacher_ref = db_pees.collection("users").document(teacher_id)
#         teacher_doc = teacher_ref.get()

#         if not teacher_doc.exists:
#             return jsonify({"error": f"Teacher ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
#         assigned_grades = teacher_data.get("assignedGrades", {})

#         # Flatten assigned grades & subjects into a list
#         teacher_grade_subjects = set()
#         for grade, classes in assigned_grades.items():
#             for class_name, subjects in classes.items():
#                 for subject in subjects:
#                     teacher_grade_subjects.add((grade, subject))

#         # Fetch curriculum matching teacher's assigned grades & subjects
#         docs = curriculum_ref.stream()
#         filtered_curriculum = [
#             {
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": doc.get("subject"),
#             }
#             for doc in docs
#             if (doc.get("grade"), doc.get("subject")) in teacher_grade_subjects
#         ]
#     else:
#         # Fetch all curriculums if no teacher filter
#         docs = curriculum_ref.stream()
#         filtered_curriculum = [
#             {
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": doc.get("subject"),
#             }
#             for doc in docs
#         ]

#     return jsonify({"curriculum": filtered_curriculum}), 200


# Function to clean extracted text
def clean_text(raw_text):
    """
    Cleans the extracted OCR text by:
    - Removing extra whitespace
    - Removing special characters
    - Fixing common OCR errors
    """
    import re

    # Remove extra whitespace and line breaks
    cleaned = re.sub(r"\s+", " ", raw_text)

    # Remove special characters (retain alphanumerics and basic punctuation)
    cleaned = re.sub(r"[^a-zA-Z0-9.,!?\'\";:()\\-]", " ", cleaned)

    # Normalize spaces
    cleaned = re.sub(r"\s+", " ", cleaned).strip()

    return cleaned


# from openai import AsyncOpenAI

# async def evaluate_exam_script_with_groq(
#     extracted_text, relevant_text, image_url, language
# ):
#     try:
#         client = AsyncOpenAI(api_key=OPENAI_API_KEY)
#         all_responses = []
#         batch_size = 1  # Process 100 chunks at a time
#         total_chunks = len(extracted_text)

#         print(f"Total chunks: {total_chunks}, Processing in batches of {batch_size}.")

#         for i in range(0, total_chunks, batch_size):
#             batch = extracted_text[i : i + batch_size]  # Get 100 chunks
#             batch_text = "\n".join(batch)  # Combine into a single string

#             prompt = f"""
#             ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
#             *Return Analysis Of All Data In Exam Script Raw Data All Questions Evaluation DO NOT Cut Questions or Answers*                                                                                                                                       |
#             *Students Exam Script Raw Data :- {batch_text} This Needs To be converted into proper format before generating response and analysis generation. Extract all questions and their answers from Raw Data.*                                            |
#             ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________|

#             You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge.

#             After this, check every extracted question and properly analyze it with curriculum data. Respond in the format below:

#             STRICT REQUIREMENT: EXTRACT TEXT AND PROVIDE PROPER QUESTION FORMATTING AND ANSWERS

#             *Example Output*:
#             Exam Script Question 1  : [Extracted Question Text]
#             Correct Answer : [Correct Answer]
#             User's Answer : [User's Given Answer]

#             And so on, until all questions are processed. Ensure each question's correct answer has a justification.

#             After all, count all correct answers in the exam script and return the count like:
#             - Correct Answers: [count]
#             - Incorrect Answers: [count]
#             """

#             response = await client.chat.completions.create(
#                 model="gpt-4o",
#                 messages=[
#                     {
#                         "role": "system",
#                         "content": f"You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge {relevant_text}.",
#                     },
#                     {"role": "user", "content": prompt},
#                 ],
#                 stream=False,
#                 temperature=0.2,
#             )

#             # Extract response
#             evaluation_report = response.choices[0].message.content.strip()
#             all_responses.append(evaluation_report)

#         # Combine all batch responses
#         final_report = "\n\n".join(all_responses)

#         # Translate if language is Arabic
#         if language.lower() == "ar":
#             final_report = await translate(final_report, "ar")

#         return final_report

#     except Exception as e:
#         return f"Error during evaluation: {str(e)}"

from openai import AsyncOpenAI


async def evaluate_exam_script_with_groq(
    extracted_text, relevant_text, image_url, language
):
    try:
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)
        all_responses = []
        batch_size = 2000  # Process 100 chunks at a time
        total_chunks = len(extracted_text)

        print(f"Total chunks: {total_chunks}, Processing in batches of {batch_size}.")

        for i in range(0, total_chunks, batch_size):
            batch = extracted_text[i : i + batch_size]  # Get 100 chunks
            batch_text = "\n".join(batch)  # Combine into a single string

            prompt = f"""
            _____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            ****In Response Return All Questions Answer Dont provide placeholder i want evaluation for each question and answer.****
            ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            *Return Analysis Of All Data In Exam Script Raw Data All Questions Evaluation DO NOT Cut Questions or Answers*                                                                                                                                      |
            *Students Exam Script Raw Data :- {batch_text} This Needs To be converted into proper format before generating response and analysis generation. Extract all questions and their answers from Raw Data.*                                            |
            ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________|

            You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge.

            After this, check every extracted question and properly analyze it with curriculum data. Respond in the format below:

            STRICT REQUIREMENT: EXTRACT TEXT AND PROVIDE PROPER QUESTION FORMATTING AND ANSWERS

            *Example Output*:
            Exam Script Question 1  : [Extracted Question Text]
            Correct Answer : [Correct Answer]
            User's Answer : [User's Given Answer]

            And so on, until all questions are processed. Ensure each question's correct answer has a justification.

            After all, count all correct answers in the exam script and return the count like:
            - Correct Answers: [count]
            - Incorrect Answers: [count]
            """

            response = await client.chat.completions.create(
                model="gpt-4.1-mini-2025-04-14",
                messages=[
                    {
                        "role": "system",
                        "content": f"You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge {relevant_text}. If the batch text and the relevant text subject are not the same, explicitly state: 'Wrong curriculum.'",  # if batch text and relevant text:- subject are not same then say wrong curricluj
                    },
                    {"role": "user", "content": prompt},
                ],
                stream=False,
                temperature=0,
            )

            # Extract response
            evaluation_report = response.choices[0].message.content.strip()
            all_responses.append(evaluation_report)

        # Combine all batch responses
        final_report = "\n\n".join(all_responses)

        # Translate if language is Arabic
        if language.lower() == "ar":
            final_report = await translate(final_report, "ar")

        return final_report

    except Exception as e:
        return f"Error during evaluation: {str(e)}"


async def translate(text: str, target_language: str) -> str:
    """
    Asynchronously translates input text into the target language using OpenAI's GPT model.

    :param text: The text to be translated.
    :param target_language: The target language code (e.g., "ar" for Arabic, "fr" for French).
    :return: Translated text.
    """
    try:
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)

        response = await client.chat.completions.create(
            model="gpt-4.1-mini-2025-04-14",
            messages=[
                {
                    "role": "system",
                    "content": f"You are a professional translator. Translate the following text to {target_language} Ensure while tranlate dont change its meaning return direct translated text Also Translate all text into specified target langauge {target_language} each and every word.",
                },
                {"role": "user", "content": text},
            ],
            stream=False,
        )

        # Extract translated text
        translated_text = response.choices[0].message.content.strip()
        return translated_text

    except Exception as e:
        return f"Translation Error: {str(e)}"


import os
import requests
from langchain_community.vectorstores import FAISS
from langchain_openai.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, Docx2txtLoader
from firebase_admin import storage, firestore, credentials
from langchain_openai import ChatOpenAI
from langchain.prompts import PromptTemplate
import firebase_admin
import uuid
import time
from openai import AsyncOpenAI
import json
from test2 import extract_from_pdf

# Initialize Firestore for "aischool"
creds_aischool = credentials.Certificate(
    "aischool-ba7c6-firebase-adminsdk-n8tjs-59b0bf7672.json"
)
# app_aischool = firebase_admin.initialize_app(
#     creds_aischool, {"storageBucket": "aischool-ba7c6.appspot.com"}, name="aischool_app"
# )  # Named to avoid conflicts

# Firestore & Storage for "aischool"
bucket = storage.bucket(app=app_aischool)
db_aischool = firestore.client(app=app_aischool)  # Primary Firestore (aischool)


# Initialize Firestore for "pees"
creds_pees = credentials.Certificate(
    "serviceAccountKey.json"
)  # Path to pees service account key
# app_pees = firebase_admin.initialize_app(
#     creds_pees, name="pees_app"
# )  # Named to avoid conflicts
db_pees = firestore.client(app=app_pees)  # Secondary Firestore (pees)


# OpenAI API Key
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')

client = AsyncOpenAI(api_key=OPENAI_API_KEY)


def check_index_in_bucket(curriculum_id):
    """Check if FAISS index exists in Firebase Storage"""
    blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss")
    return blob.exists()


def download_index_from_bucket(curriculum_id):
    """Download FAISS index from Firebase Storage"""
    if not os.path.exists(f"faiss_index_{curriculum_id}"):
        os.makedirs(f"faiss_index_{curriculum_id}")

    faiss_blob = bucket.blob(
        f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss"
    )
    faiss_blob.download_to_filename(f"faiss_index_{curriculum_id}/index.faiss")

    pkl_blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.pkl")
    pkl_blob.download_to_filename(f"faiss_index_{curriculum_id}/index.pkl")


def upload_index_to_bucket(curriculum_id):
    """Upload FAISS index to Firebase Storage"""
    faiss_blob = bucket.blob(
        f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss"
    )
    faiss_blob.upload_from_filename(f"faiss_index_{curriculum_id}/index.faiss")

    pkl_blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.pkl")
    pkl_blob.upload_from_filename(f"faiss_index_{curriculum_id}/index.pkl")


def download_file(url, curriculum_id):
    """Download the curriculum file from a URL"""
    file_extension = url.split(".")[-1]
    file_path = f"curriculum_{curriculum_id}.{file_extension}"

    response = requests.get(url)
    with open(file_path, "wb") as f:
        f.write(response.content)

    return file_path


def vector_embedding(curriculum_id, file_url):
    """Load or create FAISS vector embeddings from curriculum documents"""
    embeddings = OpenAIEmbeddings(api_key=OPENAI_API_KEY)

    if check_index_in_bucket(curriculum_id):
        print("Loading FAISS index from Firebase Storage...")
        download_index_from_bucket(curriculum_id)
        vectors = FAISS.load_local(
            f"faiss_index_{curriculum_id}",
            embeddings,
            allow_dangerous_deserialization=True,
        )
    else:
        print("Creating FAISS index...")
        file_path = download_file(file_url, curriculum_id)
        file_extension = file_path.split(".")[-1]

        # Load the document based on file type
        if file_extension == "pdf":
            loader = PyPDFLoader(file_path)
        elif file_extension == "docx":
            loader = Docx2txtLoader(file_path)
        else:
            raise ValueError("Unsupported file type. Only PDF and DOCX are allowed.")

        docs = loader.load()

        # Split document into smaller chunks for vector embedding
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=10000, chunk_overlap=1500
        )
        final_documents = text_splitter.split_documents(docs)

        # Convert documents to FAISS vectors
        vectors = FAISS.from_documents(final_documents, embeddings)

        # Save FAISS index locally and upload to Firebase
        vectors.save_local(f"faiss_index_{curriculum_id}")
        upload_index_to_bucket(curriculum_id)

        # Remove downloaded file to free space
        os.remove(file_path)

    return vectors


async def retrieve_relevant_text(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 5, "max_length": 900})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


async def retrieve_relevant_text1(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 1, "max_length": 100})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


async def retrieve_relevant_text2(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 10, "max_length": 2000})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


import shutil


def delete_local_faiss_index(curriculum_id):
    local_dir = f"faiss_index_{curriculum_id}"
    if os.path.exists(local_dir):
        shutil.rmtree(local_dir)  # Deletes the directory and all its contents


def get_student_grade(student_id):
    student_doc = db_pees.collection("students").document(student_id).get()
    student_data = student_doc.to_dict()
    grades_map = student_data.get("assignedGrades", {}).get("grades", {})

    # Assuming there's only one key like "GRADE 12"
    for grade_name in grades_map.keys():
        return grade_name

    return ""


# async def generate_teaching_plan(
#     student_id,
#     curriculum_id,
#     curriculumname,
#     image_url,
#     language,
#     temp_pdf_path,
#     openai_client,
#     subject,
#     curriculum_coverage,
#     teacher_id,
#     saveInTeachingPlans=False,
# ):
#     print("--- RUNNING FUNCTION AT LINE 1399 ---")
#     """Generate a customized teaching plan using AsyncOpenAI and store it in Firestore."""

#     query = f""" find relevant context from curriculum text using given curriculum coverage topics:- {curriculum_coverage}"""
#     # Retrieve relevant text
#     relevant_text = await retrieve_relevant_text(curriculum_id, query)
#     # extracted_text1 = "\n\n".join(extracted_text)

#     # Check if the student exists in Firestore
#     student_ref = db_pees.collection("students").document(student_id)
#     student_doc = student_ref.get()

#     if student_doc.exists:
#         student_data = student_doc.to_dict()
#         student_name = (
#             student_data.get("profileInfo", {})
#             .get("personalInformation", {})
#             .get("name", "")
#         )
#     else:
#         student_name = ""

#     print("????????????????????", student_name, "????????????????????")

#     student_grade = get_student_grade(student_id)

#     evaluation_report = await extract_from_pdf(
#         temp_pdf_path,
#         openai_client,
#         curriculum_id,
#         subject,
#         curriculum_coverage,
#         language,
#         # student_grade,
#     )

#     # Define system and user messages for the OpenAI completion request
#     messages = [
#         {
#             "role": "system",
#             "content": "You are an AI tutor creating a customized teaching plan based on curriculum data and student performance analysis STRICTLY CHECK LANGUAGE CONDITION OF RELEVANT TEXT ARABIC AND ENGLISH ONE.",
#         },
#         {
#             "role": "user",
#             "content": f"""
#             **Student Name is :- {student_name}**
#         Based on the extracted curriculum text, retrieved relevant information, and analyzed student performance, generate a structured teaching plan that is The plan should clearly highlight identified areas where improvements are required based on the analysis of the exams in JSON format.  

#         The AI should assess student answers from the provided exam image and compare them against the curriculum. It should identify individual student strengths and weaknesses and accumulate this knowledge over time to track their progress. The generated teaching plan should incorporate these insights to help teachers create targeted learning strategies.  


#         --- Retrieved Relevant Text ---
#         {relevant_text}

#         ***Ensure Generated Teaching Plan Must be In Same Langauge as relevant Text have
#         For Example If curriculum Relevant text have langauge of Arabic then full teaching plan Output Generate in Arabic if teaching plan is in english then generate teaching Plan in English.

#         Don't Change Field name of Json Output : assessmentMethods, instructionalStrategies, learningObjectives, recommendedResources,timeline This Must be same structure and Name But Data inside is in language condition of arabic and english ensure *Langauge* is the strict requirement HERE.***


#         ***The plan should be comprehensive and addressing all aspects of the student performance with very clear instructions and action plan Ensure Every Description Generated is of 3 Paragraph Atleast with personalization as Student Name.***

#         ***The plan should clearly highlight identified areas where improvements are required based on the analysis of Exam Evaluation Report (Having Correct and Wrong Answer Based on Curriculum Exam) :-  {evaluation_report}***

#         --- JSON Output Format ---
#         {{
#           "assessmentMethods": {{
#             "method1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "method2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "instructionalStrategies": {{
#             "strategy1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "strategy2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "learningObjectives": {{
#             "objective1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "objective2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "recommendedResources": {{
#             "resource1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "resource2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }},
#           "timeline": {{
#             "week1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
#             "week2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
#           }}
#         }}
#         """,
#         },
#     ]

#     # Send request to OpenAI's GPT model asynchronously
#     response = await client.chat.completions.create(
#         model="gpt-4.1-mini-2025-04-14",
#         messages=messages,
#         response_format={"type": "json_object"},
#         stream=False,
#     )

#     if response and response.choices:
#         try:
#             # Extract response and parse JSON
#             if saveInTeachingPlans:
#                 teaching_plan_json = json.loads(
#                     response.choices[0].message.content.strip()
#                 )

#                 # Generate a unique plan ID
#                 plan_id = str(uuid.uuid4()).replace("-", "_")

#                 teaching_plan_json["planId"] = plan_id

#                 if not student_doc.exists:
#                     return {"error": f"Student with ID {student_id} not found"}

#                 # Store the structured JSON teaching plan in Firestore
#                 student_ref.update(
#                     {
#                         f"teachingPlans.{plan_id}": {
#                             "actionPlan": teaching_plan_json,
#                             "createdAt": time.strftime(
#                                 "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                             ),
#                         }
#                     }
#                 )

#                 # Create a document ID using student_id and subject_id
#                 teaching_plan_doc_id = f"{student_id}"

#                 # Reference to the new TeachingPlans collection
#                 teaching_plan_ref = db_pees.collection("TeachingPlans").document(
#                     teaching_plan_doc_id
#                 )

#                 # Store the structured JSON teaching plan in the TeachingPlans collection
#                 # Update ONLY the specific subject inside the document, preserving other subjects
#                 teaching_plan_ref.set(
#                     {
#                         "subjects": {
#                             subject: {
#                                 "studentId": student_id,
#                                 "subjectId": subject,
#                                 "actionPlan": teaching_plan_json,
#                                 "teacher_id": teacher_id,
#                                 "createdAt": time.strftime(
#                                     "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
#                                 ),
#                             }
#                         }
#                     },
#                     merge=True,  # ?? Ensures only the given subject is updated, keeping other subjects intact
#                 )

#                 # evaluation_report = await evaluate_exam_script_with_groq(
#                 #     extracted_text,
#                 #     relevant_text=relevant_text,
#                 #     image_url=image_url,
#                 #     language=language,
#                 # )

#                 student_ref.update({"evaluation": evaluation_report})

#                 print(
#                     "\n? **Teaching Plan Stored in Firestore as JSON!**\n",
#                     teaching_plan_json,
#                 )
#                 delete_local_faiss_index(curriculum_id)

#                 return teaching_plan_json, evaluation_report, plan_id
#             else:
#                 teaching_plan_json, evaluation_report, plan_id = (
#                     "",
#                     evaluation_report,
#                     "",
#                 )
#                 student_ref.update({"evaluation": evaluation_report})
#                 return teaching_plan_json, evaluation_report, plan_id

#         except json.JSONDecodeError:
#             return {
#                 "error": "Failed to parse teaching plan response. AI did not return valid JSON."
#             }
#     else:
#         return {"error": "No valid teaching plan generated."}



# from flask import jsonify

# async def get_curriculum_list(teacher_id=None):
#     print("--- 1 --- RUNNING NEW CASE-INSENSITIVE CODE V3 (OUTPUT ALIGNMENT FIX) --- 1 ---")
    
#     curriculum_ref = db_aischool.collection("curriculum")
#     filtered_curriculum = []

#     # 1. Fetch ALL curriculums from db_aischool
#     all_curriculums = []
#     try:
#         docs = curriculum_ref.stream()
#         for doc in docs:
#             all_curriculums.append({
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": doc.get("subject"),
#             })
#     except Exception as e:
#         return jsonify({"error": f"Failed to fetch all curriculums: {str(e)}"}), 500

#     if teacher_id:
#         # 2. Fetch teacher's assigned grades & subjects
#         teacher_ref = db_pees.collection("users").document(teacher_id)
#         teacher_doc = teacher_ref.get() 

#         if not teacher_doc.exists:
#             return jsonify({"error": f"Teacher ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
#         assigned_grades = teacher_data.get("assignedGrades", {})
        
#         # Handle nested grades structure
#         if 'grades' in assigned_grades and isinstance(assigned_grades['grades'], dict):
#             assigned_grades = assigned_grades['grades']

#         # 3. Flatten assigned grades & subjects into a set of LOWERCASE and TRIMMED tuples
#         teacher_grade_subjects_lower = set()
#         for grade, classes in assigned_grades.items():
#             # Clean teacher's grade (PEES key): lower, replace('_', ' '), strip.
#             grade_str_clean = str(grade).lower().replace('_', ' ').strip()
            
#             for class_name, subjects in classes.items():
#                 for subject in subjects:
#                     # Clean teacher's subject: lower and strip.
#                     subject_str_clean = str(subject).lower().strip() 
                    
#                     # Add the cleaned pair
#                     teacher_grade_subjects_lower.add((grade_str_clean, subject_str_clean))

#         # 4. Filter the full curriculum list in Python (Case/Space-friendly)
#         for curriculum in all_curriculums:
#             curriculum_grade = curriculum.get("grade")
#             curriculum_subject = curriculum.get("subject")

#             if curriculum_grade and curriculum_subject:
                
#                 # --- START GRADE CLEANING FOR MATCHING ---
#                 curriculum_grade_clean = str(curriculum_grade).lower().replace('_', ' ').strip()
                
#                 # Apply the fix needed for successful matching (converts "grade 11 (literature)" to "grade 11(literature)")
#                 curriculum_grade_clean_for_match = curriculum_grade_clean.replace(' (', '(')
#                 # --- END GRADE CLEANING FOR MATCHING ---

#                 # Clean the subject
#                 curriculum_subject_clean = str(curriculum_subject).lower().strip()
                
#                 # Create the final pair for comparison
#                 curriculum_pair_clean = (
#                     curriculum_grade_clean_for_match, # Used for comparison against the teacher's key
#                     curriculum_subject_clean
#                 )
                
#                 # If the pair matches, process the curriculum item
#                 if curriculum_pair_clean in teacher_grade_subjects_lower:
                    
#                     # 💥 START OUTPUT FORMATTING EXCEPTION 💥
#                     # Default output grade name is the value from the curriculum DB
#                     output_grade_name = curriculum.get("grade") 
                    
#                     # Check if the match was for the specific grade requiring formatting
#                     if curriculum_grade_clean_for_match == "grade 11(literature)":
#                         # Hardcode the output to match the /students/list API and the client widget model
#                         output_grade_name = "GRADE 11(Literature)"
                    
#                     # All other grades (e.g., "Grade 11(Science)", "Grade 10") retain their original format
#                     # 💥 END OUTPUT FORMATTING EXCEPTION 💥
                    
#                     # Create a copy and apply the potentially modified grade name
#                     curriculum_item_to_add = curriculum.copy()
#                     curriculum_item_to_add["grade"] = output_grade_name
                    
#                     filtered_curriculum.append(curriculum_item_to_add)

#     else:
#         # If no teacher_id, just return the full list
#         filtered_curriculum = all_curriculums

#     return jsonify({"curriculum": filtered_curriculum}), 200

# from flask import jsonify, request
# from flask import jsonify
# from flask import jsonify

# async def get_curriculum_list(teacher_id=None):
#     print("--- 1 --- RUNNING NEW HEADMASTER ROLE FIX (v4) --- 1 ---")
    
#     curriculum_ref = db_aischool.collection("curriculum")
#     all_curriculums = []
#     try:
#         docs = curriculum_ref.stream()
#         for doc in docs:
#             all_curriculums.append({
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": str(doc.get("subject")).strip(),
#             })
#     except Exception as e:
#         return jsonify({"error": f"Failed to fetch all curriculums: {str(e)}"}), 500

#     if teacher_id:
#         # 2. Fetch user's document
#         teacher_ref = db_pees.collection("users").document(teacher_id)
#         teacher_doc = teacher_ref.get() 

#         if not teacher_doc.exists:
#             return jsonify({"error": f"User ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
        
#         # --- START HEADMASTER FIX ---
        
#         # [FIX]: The 'role' is at the TOP LEVEL of the document, 
#         # not inside profileInfo.
#         teacher_role_raw = teacher_data.get("role") 
        
#         print(f"--- 2 --- [DEBUG] Found raw role: '{teacher_role_raw}' (Type: {type(teacher_role_raw)})")
        
#         # Safely convert to lowercase string
#         teacher_role = ""
#         if isinstance(teacher_role_raw, str):
#             teacher_role = teacher_role_raw.lower()
        
#         print(f"--- 3 --- [DEBUG] Cleaned role: '{teacher_role}'")
#         # --- END HEADMASTER FIX ---

#         # Check if the role is a headmaster or admin
#         if teacher_role in ["headmaster", "admin", "principal"]:
#             print(f"--- 4 --- SUCCESS: User {teacher_id} IS an admin/headmaster. Returning all curriculums.")
#             return jsonify({"curriculum": all_curriculums}), 200
            
#         # 3. If NOT a headmaster, proceed with the normal filtering logic
#         print(f"--- 4 --- FAILED: User {teacher_id} is a regular teacher. Filtering...")
#         assigned_grades = teacher_data.get("assignedGrades", {})
        
#         if 'grades' in assigned_grades and isinstance(assigned_grades['grades'], dict):
#             assigned_grades = assigned_grades['grades']

#         # (Rest of the filtering code is unchanged)
#         teacher_grade_subjects_lower = set()
#         for grade, classes in assigned_grades.items():
#             grade_str_clean = str(grade).lower().replace('_', ' ').strip()
#             for class_name, subjects in classes.items():
#                 for subject in subjects:
#                     subject_str_clean = str(subject).lower().strip() 
#                     teacher_grade_subjects_lower.add((grade_str_clean, subject_str_clean))

#         filtered_curriculum = []
#         for curriculum in all_curriculums:
#             curriculum_grade = curriculum.get("grade")
#             curriculum_subject = curriculum.get("subject")

#             if curriculum_grade and curriculum_subject:
#                 curriculum_grade_clean = str(curriculum_grade).lower().replace('_', ' ').strip()
#                 curriculum_grade_clean_for_match = curriculum_grade_clean.replace(' (', '(')
#                 curriculum_subject_clean = str(curriculum_subject).lower().strip()
                
#                 curriculum_pair_clean = (
#                     curriculum_grade_clean_for_match,
#                     curriculum_subject_clean
#                 )
                
#                 if curriculum_pair_clean in teacher_grade_subjects_lower:
#                     output_grade_name = curriculum.get("grade") 
#                     if curriculum_grade_clean_for_match == "grade 11(literature)":
#                         output_grade_name = "GRADE 11(Literature)"
                    
#                     curriculum_item_to_add = curriculum.copy()
#                     curriculum_item_to_add["grade"] = output_grade_name
                    
#                     filtered_curriculum.append(curriculum_item_to_add)
        
#         return jsonify({"curriculum": filtered_curriculum}), 200

#     else:
#         # If no teacher_id, just return the full list
#         print("--- 2 --- No teacher_id provided. Returning all curriculums.")
#         return jsonify({"curriculum": all_curriculums}), 200

# import re
# from flask import jsonify, request

# # --- HELPER: Output Normalizer ---
# def normalize_grade_key_output(key):
#     """
#     Converts 'Grade 10', 'Grade 10 ', 'grade-10' -> 'GRADE_10'
#     Ensures the API response matches the internal keys used by the App.
#     """
#     if not key: return ""
#     key = str(key).upper().strip()
#     # Replace spaces, dots, slashes, hyphens with underscore
#     key = re.sub(r'[\s\./\-]+', '_', key)
#     # Clean up extra underscores around parentheses
#     key = key.replace('_(', '(').replace(')_', ')')
#     # Clean up repeated underscores
#     key = re.sub(r'_{2,}', '_', key)
#     return key.strip('_')


# async def get_curriculum_list(teacher_id=None):
#     print("--- 1 --- RUNNING CURRICULUM FETCH WITH NORMALIZATION ---")
    
#     # Assume db_aischool and db_pees are globally initialized
#     curriculum_ref = db_aischool.collection("curriculum")
#     all_curriculums = []
#     try:
#         docs = curriculum_ref.stream()
#         for doc in docs:
#             all_curriculums.append({
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": str(doc.get("subject")).strip(),
#             })
#     except Exception as e:
#         return jsonify({"error": f"Failed to fetch all curriculums: {str(e)}"}), 500

#     if teacher_id:
#         # 2. Fetch user's document
#         teacher_ref = db_pees.collection("users").document(teacher_id)
#         teacher_doc = teacher_ref.get() 

#         if not teacher_doc.exists:
#             return jsonify({"error": f"User ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
        
#         # --- START HEADMASTER CHECK ---
#         teacher_role_raw = teacher_data.get("role") 
        
#         # Safely convert to lowercase string
#         teacher_role = ""
#         if isinstance(teacher_role_raw, str):
#             teacher_role = teacher_role_raw.lower()
        
#         # Check if the role is a headmaster or admin
#         if teacher_role in ["headmaster", "admin", "principal"]:
#             print(f"--- 4 --- SUCCESS: User {teacher_id} IS Admin. Returning all.")
            
#             # [FIX] Normalize grades for Headmaster too, or App will show empty lists
#             for curr in all_curriculums:
#                 curr["grade"] = normalize_grade_key_output(curr["grade"])
                
#             return jsonify({"curriculum": all_curriculums}), 200
            
#         # 3. If NOT a headmaster, proceed with the normal filtering logic
#         print(f"--- 4 --- FAILED: User {teacher_id} is a regular teacher. Filtering...")
#         assigned_grades = teacher_data.get("assignedGrades", {})
        
#         if 'grades' in assigned_grades and isinstance(assigned_grades['grades'], dict):
#             assigned_grades = assigned_grades['grades']

#         # (Rest of the filtering code is unchanged)
#         teacher_grade_subjects_lower = set()
#         for grade, classes in assigned_grades.items():
#             grade_str_clean = str(grade).lower().replace('_', ' ').strip()
#             for class_name, subjects in classes.items():
#                 for subject in subjects:
#                     subject_str_clean = str(subject).lower().strip() 
#                     teacher_grade_subjects_lower.add((grade_str_clean, subject_str_clean))

#         filtered_curriculum = []
#         for curriculum in all_curriculums:
#             curriculum_grade = curriculum.get("grade")
#             curriculum_subject = curriculum.get("subject")

#             if curriculum_grade and curriculum_subject:
#                 curriculum_grade_clean = str(curriculum_grade).lower().replace('_', ' ').strip()
#                 curriculum_grade_clean_for_match = curriculum_grade_clean.replace(' (', '(')
#                 curriculum_subject_clean = str(curriculum_subject).lower().strip()
                
#                 curriculum_pair_clean = (
#                     curriculum_grade_clean_for_match,
#                     curriculum_subject_clean
#                 )
                
#                 if curriculum_pair_clean in teacher_grade_subjects_lower:
                    
#                     # [FIX START] Apply Normalization Default
#                     output_grade_name = normalize_grade_key_output(curriculum.get("grade"))
#                     # [FIX END]
                    
#                     # [PRESERVED LOGIC] Your specific Grade 11 override
#                     # This overwrites the normalization if this specific condition is met
#                     if curriculum_grade_clean_for_match == "grade 11(literature)":
#                         output_grade_name = "GRADE 11(Literature)"
                    
#                     curriculum_item_to_add = curriculum.copy()
#                     curriculum_item_to_add["grade"] = output_grade_name
                    
#                     filtered_curriculum.append(curriculum_item_to_add)
        
#         return jsonify({"curriculum": filtered_curriculum}), 200

#     else:
#         # If no teacher_id, just return the full list
#         print("--- 2 --- No teacher_id provided. Returning all curriculums.")
#         # [FIX] Normalize here as well
#         for curr in all_curriculums:
#             curr["grade"] = normalize_grade_key_output(curr["grade"])
            
#         return jsonify({"curriculum": all_curriculums}), 200
import re
from flask import jsonify, request

# Assuming 'db_aischool' and 'db_pees' are globally initialized Firestore client instances
# 'app' must also be initialized globally for the routes to work.

# --- HELPER: Output Normalizer (1: STANDARDIZED TO UNDERSCORE) ---
def normalize_grade_key_output_underscore(key):
    """
    Converts variations like 'Grade 5', 'Grade5', 'Grade_5' -> 'GRADE_5'.
    This is one of the two formats required by the frontend widget for filtering.
    """
    if not key: return ""
    key = str(key).upper().strip()
    
    # 1. Replace spaces, dots, hyphens with UNDERSCORE
    key = re.sub(r'[\s\.\-]+', '_', key)
    
    # 2. Collapse multiple underscores into one
    key = re.sub(r'_{2,}', '_', key)
    
    # 3. Remove leading/trailing underscores
    return key.strip('_')

# --- HELPER: Output Normalizer (2: STANDARDIZED TO SPACE) ---
def normalize_grade_key_output_space(key):
    """
    Converts variations like 'Grade 5', 'Grade5', 'Grade_5' -> 'GRADE 5'.
    This is the second format required by the frontend widget for filtering.
    """
    if not key: return ""
    key = str(key).upper().strip()
    
    # 1. Replace underscores, dots, hyphens with SPACE
    key = re.sub(r'[_\.\-]+', ' ', key)
    
    # 2. Collapse multiple spaces into one
    key = re.sub(r'\s+', ' ', key)
    
    # 3. Remove leading/trailing spaces
    return key.strip()

# --- HELPER: Internal Match Key Sanitizer (ROBUST MATCHING) ---
def sanitize_grade_key_match(key):
    """
    Creates a simple, alphanumeric-only key (e.g., 'grade5science') for robust internal comparison, 
    ignoring case, spaces, and underscores. This helper is critical for matching teacher assignments.
    """
    if not key: return ""
    key = str(key).lower().strip()
    # Remove all non-alphanumeric characters (spaces, underscores, parentheses, etc.)
    key = re.sub(r'[^a-z0-9]+', '', key)
    return key


# async def get_curriculum_list(teacher_id=None):
#     """
#     Core logic to fetch curriculum and filter based on teacher assignments (if teacher_id is provided).
#     This function generates dual grade format entries (GRADE_X and GRADE X) for each curriculum item.
#     """
#     print("--- 1 --- RUNNING NEW HEADMASTER ROLE FIX (v4) --- 1 ---")
    
#     curriculum_ref = db_aischool.collection("curriculum")
#     all_curriculums = []
#     try:
#         docs = curriculum_ref.stream()
#         for doc in docs:
#             # Fetch raw data
#             all_curriculums.append({
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"), 
#                 "subject": str(doc.get("subject")).strip(),
#             })
#     except Exception as e:
#         return jsonify({"error": f"Failed to fetch all curriculums: {str(e)}"}), 500

#     # Determine the source list: all curriculums or filtered list
#     curriculum_source_list = all_curriculums
    
#     if teacher_id:
#         teacher_ref = db_pees.collection("users").document(teacher_id)
#         teacher_doc = teacher_ref.get() 

#         if not teacher_doc.exists:
#             return jsonify({"error": f"User ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
        
#         # --- HEADMASTER/ADMIN CHECK (Based on Reference) ---
#         teacher_role_raw = teacher_data.get("role") 
        
#         print(f"--- 2 --- [DEBUG] Found raw role: '{teacher_role_raw}' (Type: {type(teacher_role_raw)})")
        
#         teacher_role = ""
#         if isinstance(teacher_role_raw, str):
#             teacher_role = teacher_role_raw.lower()
            
#         print(f"--- 3 --- [DEBUG] Cleaned role: '{teacher_role}'")
        
#         if teacher_role in ["headmaster", "admin", "principal"]:
#             print(f"--- 4 --- SUCCESS: User {teacher_id} IS an admin/headmaster. Returning all curriculums.")
#             # curriculum_source_list remains all_curriculums
#         else:
#             # --- REGULAR TEACHER FILTERING (Based on Reference) ---
#             print(f"--- 4 --- FAILED: User {teacher_id} is a regular teacher. Filtering...")
#             assigned_grades = teacher_data.get("assignedGrades", {})
#             if 'grades' in assigned_grades and isinstance(assigned_grades['grades'], dict):
#                 assigned_grades = assigned_grades['grades']

#             # Build lookup set using the ROBUST sanitization logic
#             teacher_grade_subjects_match = set()
#             for grade, classes in assigned_grades.items():
#                 # Use robust sanitizer for internal matching key
#                 grade_match_key = sanitize_grade_key_match(grade)
                
#                 for class_name, subjects in classes.items():
#                     for subject in subjects:
#                         subject_clean = str(subject).lower().strip() 
#                         teacher_grade_subjects_match.add((grade_match_key, subject_clean))
            
#             filtered_curriculum_single_format = []
#             for curriculum in all_curriculums:
#                 raw_curr_grade = curriculum.get("grade")
#                 raw_curr_subject = curriculum.get("subject")

#                 if raw_curr_grade and raw_curr_subject:
#                     # Use robust sanitizer for internal matching key
#                     curr_grade_match_key = sanitize_grade_key_match(raw_curr_grade)
#                     curr_subject_clean = str(raw_curr_subject).lower().strip()
                    
#                     curriculum_pair_match = (curr_grade_match_key, curr_subject_clean)
                    
#                     if curriculum_pair_match in teacher_grade_subjects_match:
#                         filtered_curriculum_single_format.append(curriculum)
            
#             curriculum_source_list = filtered_curriculum_single_format

#     else:
#         # If no teacher_id, just return the full list
#         print("--- 2 --- No teacher_id provided. Returning all curriculums.")
#         # curriculum_source_list remains all_curriculums

#     # --- FINAL DUAL FORMAT PROCESSING (APPLIED TO ALL RESULTS) ---
#     processed_curriculum = []
    
#     for curriculum in curriculum_source_list:
        
#         # 1. Underscore format (e.g., GRADE_5)
#         underscore_grade = normalize_grade_key_output_underscore(curriculum["grade"])
        
#         # 2. Space format (e.g., GRADE 5)
#         space_grade = normalize_grade_key_output_space(curriculum["grade"])
        
#         # Create a copy for the underscore format
#         processed_curriculum.append({**curriculum, "grade": underscore_grade})
        
#         # Create a second entry for the space format, only if it's visually different
#         if space_grade != underscore_grade:
#             item_with_space_grade = {**curriculum, "grade": space_grade}
            
#             # [PRESERVED LOGIC] Handle specific Grade 11 override if necessary
#             curr_grade_match_key = sanitize_grade_key_match(curriculum.get("grade"))
#             if curr_grade_match_key == sanitize_grade_key_match("GRADE 11(Literature)"):
#                  item_with_space_grade["grade"] = "GRADE 11(Literature)"
            
#             processed_curriculum.append(item_with_space_grade)

#     return jsonify({"curriculum": processed_curriculum}), 200
    
async def get_curriculum_list(teacher_id=None):
    """
    Core logic to fetch curriculum and filter based on teacher assignments.
    """
    print("--- 1 --- Fetching Curriculum (Hybrid Sync/Async Fix) ---")
    
    curriculum_ref = db_aischool.collection("curriculum")
    all_curriculums = []
    
    try:
        # ⚠️ CHANGED BACK TO STANDARD STREAM
        # Because db_aischool is synchronous, 'stream()' returns a standard generator.
        # We must use a standard 'for' loop, not 'async for'.
        docs = curriculum_ref.stream()
        
        for doc in docs: 
            all_curriculums.append({
                "curriculum_id": doc.id,
                "curriculum_name": doc.get("curriculum_name"),
                "grade": doc.get("grade"), 
                "subject": str(doc.get("subject")).strip(),
            })
            
    except Exception as e:
        print(f"Error fetching curriculum: {e}")
        return jsonify({"error": f"Failed to fetch all curriculums: {str(e)}"}), 500

    print(f"--- 2 --- Total Curriculums Found: {len(all_curriculums)}")

    curriculum_source_list = all_curriculums
    
    if teacher_id:
        teacher_ref = db_pees.collection("users").document(teacher_id)
        
        # ⚠️ CRITICAL CHECK:
        # If 'db_pees' is ASYNC (firestore_async), keep 'await'.
        # If 'db_pees' is SYNC (standard firestore), REMOVE 'await'.
        # Based on your previous errors, I am assuming db_pees is Async.
        try:
            teacher_doc = await teacher_ref.get()
        except TypeError:
            # Fallback if db_pees is actually synchronous
            teacher_doc = teacher_ref.get()

        if not teacher_doc.exists:
            return jsonify({"error": f"User ID {teacher_id} not found"}), 404

        teacher_data = teacher_doc.to_dict()
        
        # --- HEADMASTER/ADMIN CHECK ---
        teacher_role_raw = teacher_data.get("role") 
        teacher_role = str(teacher_role_raw).lower() if teacher_role_raw else ""
        
        print(f"--- 3 --- Role found: {teacher_role}")

        if teacher_role in ["headmaster", "admin", "principal"]:
            # Headmaster gets everything
            curriculum_source_list = all_curriculums
        else:
            # --- REGULAR TEACHER FILTERING ---
            assigned_grades = teacher_data.get("assignedGrades", {})
            if 'grades' in assigned_grades and isinstance(assigned_grades['grades'], dict):
                assigned_grades = assigned_grades['grades']

            teacher_grade_subjects_match = set()
            for grade, classes in assigned_grades.items():
                grade_match_key = sanitize_grade_key_match(grade)
                for class_name, subjects in classes.items():
                    for subject in subjects:
                        subject_clean = str(subject).lower().strip() 
                        teacher_grade_subjects_match.add((grade_match_key, subject_clean))
            
            filtered_curriculum_single_format = []
            for curriculum in all_curriculums:
                raw_curr_grade = curriculum.get("grade")
                raw_curr_subject = curriculum.get("subject")

                if raw_curr_grade and raw_curr_subject:
                    curr_grade_match_key = sanitize_grade_key_match(raw_curr_grade)
                    curr_subject_clean = str(raw_curr_subject).lower().strip()
                    
                    if (curr_grade_match_key, curr_subject_clean) in teacher_grade_subjects_match:
                        filtered_curriculum_single_format.append(curriculum)
            
            curriculum_source_list = filtered_curriculum_single_format
    else:
        print("--- 2 --- No teacher_id provided. Returning all curriculums.")

    # --- FINAL DUAL FORMAT PROCESSING ---
    processed_curriculum = []
    
    for curriculum in curriculum_source_list:
        raw_grade = curriculum.get("grade")
        
        underscore_grade = normalize_grade_key_output_underscore(raw_grade)
        space_grade = normalize_grade_key_output_space(raw_grade)
        
        processed_curriculum.append({**curriculum, "grade": underscore_grade})
        
        if space_grade != underscore_grade:
            item_with_space_grade = {**curriculum, "grade": space_grade}
            if sanitize_grade_key_match(raw_grade) == sanitize_grade_key_match("GRADE 11(Literature)"):
                 item_with_space_grade["grade"] = "GRADE 11(Literature)"
            processed_curriculum.append(item_with_space_grade)

    return jsonify({"curriculum": processed_curriculum}), 200
# NOTE: The clean_text function at the end of your original snippet is separate 
# and should not be included here, as it is not part of get_curriculum_list.


# # Function to clean extracted text
# def clean_text(raw_text):
#     """
#     Cleans the extracted OCR text by:
#     - Removing extra whitespace
#     - Removing special characters
#     - Fixing common OCR errors
#     """
#     import re

#     # Remove extra whitespace and line breaks
#     cleaned = re.sub(r"\s+", " ", raw_text)

#     # Remove special characters (retain alphanumerics and basic punctuation)
#     cleaned = re.sub(r"[^a-zA-Z0-9.,!?\'\";:()\\-]", " ", cleaned)

#     # Normalize spaces
#     cleaned = re.sub(r"\s+", " ", cleaned).strip()

#     return cleaned


# from openai import AsyncOpenAI

# async def evaluate_exam_script_with_groq(
#     extracted_text, relevant_text, image_url, language
# ):
#     try:
#         client = AsyncOpenAI(api_key=OPENAI_API_KEY)
#         all_responses = []
#         batch_size = 1  # Process 100 chunks at a time
#         total_chunks = len(extracted_text)

#         print(f"Total chunks: {total_chunks}, Processing in batches of {batch_size}.")

#         for i in range(0, total_chunks, batch_size):
#             batch = extracted_text[i : i + batch_size]  # Get 100 chunks
#             batch_text = "\n".join(batch)  # Combine into a single string

#             prompt = f"""
#             ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
#             *Return Analysis Of All Data In Exam Script Raw Data All Questions Evaluation DO NOT Cut Questions or Answers*                                                                                                                                       |
#             *Students Exam Script Raw Data :- {batch_text} This Needs To be converted into proper format before generating response and analysis generation. Extract all questions and their answers from Raw Data.*                                            |
#             ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________|

#             You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge.

#             After this, check every extracted question and properly analyze it with curriculum data. Respond in the format below:

#             STRICT REQUIREMENT: EXTRACT TEXT AND PROVIDE PROPER QUESTION FORMATTING AND ANSWERS

#             *Example Output*:
#             Exam Script Question 1  : [Extracted Question Text]
#             Correct Answer : [Correct Answer]
#             User's Answer : [User's Given Answer]

#             And so on, until all questions are processed. Ensure each question's correct answer has a justification.

#             After all, count all correct answers in the exam script and return the count like:
#             - Correct Answers: [count]
#             - Incorrect Answers: [count]
#             """

#             response = await client.chat.completions.create(
#                 model="gpt-4o",
#                 messages=[
#                     {
#                         "role": "system",
#                         "content": f"You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge {relevant_text}.",
#                     },
#                     {"role": "user", "content": prompt},
#                 ],
#                 stream=False,
#                 temperature=0.2,
#             )

#             # Extract response
#             evaluation_report = response.choices[0].message.content.strip()
#             all_responses.append(evaluation_report)

#         # Combine all batch responses
#         final_report = "\n\n".join(all_responses)

#         # Translate if language is Arabic
#         if language.lower() == "ar":
#             final_report = await translate(final_report, "ar")

#         return final_report

#     except Exception as e:
#         return f"Error during evaluation: {str(e)}"

from openai import AsyncOpenAI


async def evaluate_exam_script_with_groq(
    extracted_text, relevant_text, image_url, language
):
    try:
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)
        all_responses = []
        batch_size = 2000  # Process 100 chunks at a time
        total_chunks = len(extracted_text)

        print(f"Total chunks: {total_chunks}, Processing in batches of {batch_size}.")

        for i in range(0, total_chunks, batch_size):
            batch = extracted_text[i : i + batch_size]  # Get 100 chunks
            batch_text = "\n".join(batch)  # Combine into a single string

            prompt = f"""
            _____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            ****In Response Return All Questions Answer Dont provide placeholder i want evaluation for each question and answer.****
            ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            *Return Analysis Of All Data In Exam Script Raw Data All Questions Evaluation DO NOT Cut Questions or Answers*                                                                                                                                      |
            *Students Exam Script Raw Data :- {batch_text} This Needs To be converted into proper format before generating response and analysis generation. Extract all questions and their answers from Raw Data.*                                            |
            ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________|

            You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge.

            After this, check every extracted question and properly analyze it with curriculum data. Respond in the format below:

            STRICT REQUIREMENT: EXTRACT TEXT AND PROVIDE PROPER QUESTION FORMATTING AND ANSWERS

            *Example Output*:
            Exam Script Question 1  : [Extracted Question Text]
            Correct Answer : [Correct Answer]
            User's Answer : [User's Given Answer]

            And so on, until all questions are processed. Ensure each question's correct answer has a justification.

            After all, count all correct answers in the exam script and return the count like:
            - Correct Answers: [count]
            - Incorrect Answers: [count]
            """

            response = await client.chat.completions.create(
                model="gpt-4.1-mini-2025-04-14",
                messages=[
                    {
                        "role": "system",
                        "content": f"You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge {relevant_text}. If the batch text and the relevant text subject are not the same, explicitly state: 'Wrong curriculum.'",  # if batch text and relevant text:- subject are not same then say wrong curricluj
                    },
                    {"role": "user", "content": prompt},
                ],
                stream=False,
                temperature=0,
            )

            # Extract response
            evaluation_report = response.choices[0].message.content.strip()
            all_responses.append(evaluation_report)

        # Combine all batch responses
        final_report = "\n\n".join(all_responses)

        # Translate if language is Arabic
        if language.lower() == "ar":
            final_report = await translate(final_report, "ar")

        return final_report

    except Exception as e:
        return f"Error during evaluation: {str(e)}"


async def translate(text: str, target_language: str) -> str:
    """
    Asynchronously translates input text into the target language using OpenAI's GPT model.

    :param text: The text to be translated.
    :param target_language: The target language code (e.g., "ar" for Arabic, "fr" for French).
    :return: Translated text.
    """
    try:
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)

        response = await client.chat.completions.create(
            model="gpt-4.1-mini-2025-04-14",
            messages=[
                {
                    "role": "system",
                    "content": f"You are a professional translator. Translate the following text to {target_language} Ensure while tranlate dont change its meaning return direct translated text Also Translate all text into specified target langauge {target_language} each and every word.",
                },
                {"role": "user", "content": text},
            ],
            stream=False,
        )

        # Extract translated text
        translated_text = response.choices[0].message.content.strip()
        return translated_text

    except Exception as e:
        return f"Translation Error: {str(e)}"


import os
import requests
from langchain_community.vectorstores import FAISS
from langchain_openai.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, Docx2txtLoader
from firebase_admin import storage, firestore, credentials
from langchain_openai import ChatOpenAI
from langchain.prompts import PromptTemplate
import firebase_admin
import uuid
import time
from openai import AsyncOpenAI
import json
from test2 import extract_from_pdf

# Initialize Firestore for "aischool"
creds_aischool = credentials.Certificate(
    "aischool-ba7c6-firebase-adminsdk-n8tjs-59b0bf7672.json"
)
# app_aischool = firebase_admin.initialize_app(
#     creds_aischool, {"storageBucket": "aischool-ba7c6.appspot.com"}, name="aischool_app"
# )  # Named to avoid conflicts

# Firestore & Storage for "aischool"
bucket = storage.bucket(app=app_aischool)
db_aischool = firestore.client(app=app_aischool)  # Primary Firestore (aischool)


# Initialize Firestore for "pees"
creds_pees = credentials.Certificate(
    "serviceAccountKey.json"
)  # Path to pees service account key
# app_pees = firebase_admin.initialize_app(
#     creds_pees, name="pees_app"
# )  # Named to avoid conflicts
db_pees = firestore.client(app=app_pees)  # Secondary Firestore (pees)


# OpenAI API Key
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')

client = AsyncOpenAI(api_key=OPENAI_API_KEY)


def check_index_in_bucket(curriculum_id):
    """Check if FAISS index exists in Firebase Storage"""
    blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss")
    return blob.exists()


def download_index_from_bucket(curriculum_id):
    """Download FAISS index from Firebase Storage"""
    if not os.path.exists(f"faiss_index_{curriculum_id}"):
        os.makedirs(f"faiss_index_{curriculum_id}")

    faiss_blob = bucket.blob(
        f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss"
    )
    faiss_blob.download_to_filename(f"faiss_index_{curriculum_id}/index.faiss")

    pkl_blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.pkl")
    pkl_blob.download_to_filename(f"faiss_index_{curriculum_id}/index.pkl")


def upload_index_to_bucket(curriculum_id):
    """Upload FAISS index to Firebase Storage"""
    faiss_blob = bucket.blob(
        f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.faiss"
    )
    faiss_blob.upload_from_filename(f"faiss_index_{curriculum_id}/index.faiss")

    pkl_blob = bucket.blob(f"users/KnowledgeBase/faiss_index_{curriculum_id}/index.pkl")
    pkl_blob.upload_from_filename(f"faiss_index_{curriculum_id}/index.pkl")


def download_file(url, curriculum_id):
    """Download the curriculum file from a URL"""
    file_extension = url.split(".")[-1]
    file_path = f"curriculum_{curriculum_id}.{file_extension}"

    response = requests.get(url)
    with open(file_path, "wb") as f:
        f.write(response.content)

    return file_path


def vector_embedding(curriculum_id, file_url):
    """Load or create FAISS vector embeddings from curriculum documents"""
    embeddings = OpenAIEmbeddings(api_key=OPENAI_API_KEY)

    if check_index_in_bucket(curriculum_id):
        print("Loading FAISS index from Firebase Storage...")
        download_index_from_bucket(curriculum_id)
        vectors = FAISS.load_local(
            f"faiss_index_{curriculum_id}",
            embeddings,
            allow_dangerous_deserialization=True,
        )
    else:
        print("Creating FAISS index...")
        file_path = download_file(file_url, curriculum_id)
        file_extension = file_path.split(".")[-1]

        # Load the document based on file type
        if file_extension == "pdf":
            loader = PyPDFLoader(file_path)
        elif file_extension == "docx":
            loader = Docx2txtLoader(file_path)
        else:
            raise ValueError("Unsupported file type. Only PDF and DOCX are allowed.")

        docs = loader.load()

        # Split document into smaller chunks for vector embedding
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=10000, chunk_overlap=1500
        )
        final_documents = text_splitter.split_documents(docs)

        # Convert documents to FAISS vectors
        vectors = FAISS.from_documents(final_documents, embeddings)

        # Save FAISS index locally and upload to Firebase
        vectors.save_local(f"faiss_index_{curriculum_id}")
        upload_index_to_bucket(curriculum_id)

        # Remove downloaded file to free space
        os.remove(file_path)

    return vectors


async def retrieve_relevant_text(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 5, "max_length": 900})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


async def retrieve_relevant_text1(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 1, "max_length": 100})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


async def retrieve_relevant_text2(curriculum_id, query):
    """Retrieve and print relevant text from the curriculum"""
    curriculum_doc = db_aischool.collection("curriculum").document(curriculum_id).get()
    if not curriculum_doc.exists:
        raise ValueError(f"No curriculum found with ID: {curriculum_id}")

    file_url = curriculum_doc.to_dict().get("url")

    vectors = vector_embedding(curriculum_id, file_url)

    retriever = vectors.as_retriever(search_kwargs={"k": 10, "max_length": 2000})

    # Retrieve the most relevant documents
    docs = await retriever.ainvoke(query)

    # Extract and return the text content
    relevant_texts = "\n\n".join([doc.page_content for doc in docs])

    # print("\n?? **Extracted Relevant Text:**\n", relevant_texts)
    # Perform retrieval and print meaningful text
    delete_local_faiss_index(curriculum_id)
    return relevant_texts


import shutil


def delete_local_faiss_index(curriculum_id):
    local_dir = f"faiss_index_{curriculum_id}"
    if os.path.exists(local_dir):
        shutil.rmtree(local_dir)  # Deletes the directory and all its contents


def get_student_grade(student_id):
    student_doc = db_pees.collection("students").document(student_id).get()
    student_data = student_doc.to_dict()
    grades_map = student_data.get("assignedGrades", {}).get("grades", {})

    # Assuming there's only one key like "GRADE 12"
    for grade_name in grades_map.keys():
        return grade_name

    return ""


async def generate_teaching_plan(
    student_id,
    curriculum_id,
    curriculumname,
    image_url,
    language,
    temp_pdf_path,
    openai_client,
    subject,
    curriculum_coverage,
    teacher_id,
    saveInTeachingPlans=False,
):
    print("--- RUNNING FUNCTION AT LINE 2093 ---")
    # ... rest of function ...
    """Generate a customized teaching plan using AsyncOpenAI and store it in Firestore."""

    query = f""" find relevant context from curriculum text using given curriculum coverage topics:- {curriculum_coverage}"""
    # Retrieve relevant text
    relevant_text = await retrieve_relevant_text(curriculum_id, query)
    # extracted_text1 = "\n\n".join(extracted_text)

    # Check if the student exists in Firestore
    student_ref = db_pees.collection("students").document(student_id)
    student_doc = student_ref.get()

    if student_doc.exists:
        student_data = student_doc.to_dict()
        student_name = (
            student_data.get("profileInfo", {})
            .get("personalInformation", {})
            .get("name", "")
        )
    else:
        student_name = ""

    print("????????????????????", student_name, "????????????????????")

    student_grade = get_student_grade(student_id)

    evaluation_report = await extract_from_pdf(
        temp_pdf_path,
        openai_client,
        curriculum_id,
        subject,
        curriculum_coverage,
        language,
        # student_grade,
    )

    # Define system and user messages for the OpenAI completion request
    messages = [
        {
            "role": "system",
            "content": "You are an AI tutor creating a customized teaching plan based on curriculum data and student performance analysis STRICTLY CHECK LANGUAGE CONDITION OF RELEVANT TEXT ARABIC AND ENGLISH ONE.",
        },
        {
            "role": "user",
            "content": f"""
            **Student Name is :- {student_name}**
        Based on the extracted curriculum text, retrieved relevant information, and analyzed student performance, generate a structured teaching plan that is The plan should clearly highlight identified areas where improvements are required based on the analysis of the exams in JSON format.  

        The AI should assess student answers from the provided exam image and compare them against the curriculum. It should identify individual student strengths and weaknesses and accumulate this knowledge over time to track their progress. The generated teaching plan should incorporate these insights to help teachers create targeted learning strategies.  


        --- Retrieved Relevant Text ---
        {relevant_text}

        ***Ensure Generated Teaching Plan Must be In Same Langauge as relevant Text have
        For Example If curriculum Relevant text have langauge of Arabic then full teaching plan Output Generate in Arabic if teaching plan is in english then generate teaching Plan in English.

        Don't Change Field name of Json Output : assessmentMethods, instructionalStrategies, learningObjectives, recommendedResources,timeline This Must be same structure and Name But Data inside is in language condition of arabic and english ensure *Langauge* is the strict requirement HERE.***


        ***The plan should be comprehensive and addressing all aspects of the student performance with very clear instructions and action plan Ensure Every Description Generated is of 3 Paragraph Atleast with personalization as Student Name.***

        ***The plan should clearly highlight identified areas where improvements are required based on the analysis of Exam Evaluation Report (Having Correct and Wrong Answer Based on Curriculum Exam) :-  {evaluation_report}***

        --- JSON Output Format ---
        {{
          "assessmentMethods": {{
            "method1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
            "method2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
          }},
          "instructionalStrategies": {{
            "strategy1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
            "strategy2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
          }},
          "learningObjectives": {{
            "objective1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
            "objective2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
          }},
          "recommendedResources": {{
            "resource1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
            "resource2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
          }},
          "timeline": {{
            "week1": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME",
            "week2": "Description Detailed 3 Paragraph Atleast STEP WISE MENTION STUDENT NAME"
          }}
        }}
        """,
        },
    ]

    # Send request to OpenAI's GPT model asynchronously
    response = await client.chat.completions.create(
        model="gpt-4.1-mini-2025-04-14",
        messages=messages,
        response_format={"type": "json_object"},
        stream=False,
    )

    if response and response.choices:
        try:
            # Extract response and parse JSON
            if saveInTeachingPlans:
                teaching_plan_json = json.loads(
                    response.choices[0].message.content.strip()
                )

                # Generate a unique plan ID
                plan_id = str(uuid.uuid4()).replace("-", "_")

                teaching_plan_json["planId"] = plan_id

                if not student_doc.exists:
                    return {"error": f"Student with ID {student_id} not found"}

                # Store the structured JSON teaching plan in Firestore
                student_ref.update(
                    {
                        f"teachingPlans.{plan_id}": {
                            "actionPlan": teaching_plan_json,
                            "createdAt": time.strftime(
                                "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
                            ),
                        }
                    }
                )

                # Create a document ID using student_id and subject_id
                teaching_plan_doc_id = f"{student_id}"

                # Reference to the new TeachingPlans collection
                teaching_plan_ref = db_pees.collection("TeachingPlans").document(
                    teaching_plan_doc_id
                )

                # Store the structured JSON teaching plan in the TeachingPlans collection
                # Update ONLY the specific subject inside the document, preserving other subjects
                teaching_plan_ref.set(
                    {
                        "subjects": {
                            subject: {
                                "studentId": student_id,
                                "subjectId": subject,
                                "actionPlan": teaching_plan_json,
                                "teacher_id": teacher_id,
                                "createdAt": time.strftime(
                                    "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
                                ),
                            }
                        }
                    },
                    merge=True,  # ?? Ensures only the given subject is updated, keeping other subjects intact
                )

                # evaluation_report = await evaluate_exam_script_with_groq(
                #     extracted_text,
                #     relevant_text=relevant_text,
                #     image_url=image_url,
                #     language=language,
                # )

                student_ref.update({"evaluation": evaluation_report})

                print(
                    "\n? **Teaching Plan Stored in Firestore as JSON!**\n",
                    teaching_plan_json,
                )
                delete_local_faiss_index(curriculum_id)

                return teaching_plan_json, evaluation_report, plan_id
            else:
                teaching_plan_json, evaluation_report, plan_id = (
                    "",
                    evaluation_report,
                    "",
                )
                student_ref.update({"evaluation": evaluation_report})
                return teaching_plan_json, evaluation_report, plan_id

        except json.JSONDecodeError:
            return {
                "error": "Failed to parse teaching plan response. AI did not return valid JSON."
            }
    else:
        return {"error": "No valid teaching plan generated."}


# from flask import jsonify


# async def get_curriculum_list(teacher_id=None):
#     """
#     Retrieve curriculum IDs, names, grades, and subjects.
#     If teacher_id is provided, filter by assigned grades & subjects.
#     """
#     curriculum_ref = db_aischool.collection("curriculum")

#     if teacher_id:
#         # Fetch teacher's assigned grades & subjects
#         teacher_ref = db_pees.collection("users").document(teacher_id)
#         teacher_doc = teacher_ref.get()

#         if not teacher_doc.exists:
#             return jsonify({"error": f"Teacher ID {teacher_id} not found"}), 404

#         teacher_data = teacher_doc.to_dict()
#         assigned_grades = teacher_data.get("assignedGrades", {})

#         # Flatten assigned grades & subjects into a list
#         teacher_grade_subjects = set()
#         for grade, classes in assigned_grades.items():
#             for class_name, subjects in classes.items():
#                 for subject in subjects:
#                     teacher_grade_subjects.add((grade, subject))

#         # Fetch curriculum matching teacher's assigned grades & subjects
#         docs = curriculum_ref.stream()
#         filtered_curriculum = [
#             {
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": doc.get("subject"),
#             }
#             for doc in docs
#             if (doc.get("grade"), doc.get("subject")) in teacher_grade_subjects
#         ]
#     else:
#         # Fetch all curriculums if no teacher filter
#         docs = curriculum_ref.stream()
#         filtered_curriculum = [
#             {
#                 "curriculum_id": doc.id,
#                 "curriculum_name": doc.get("curriculum_name"),
#                 "grade": doc.get("grade"),
#                 "subject": doc.get("subject"),
#             }
#             for doc in docs
#         ]

#     return jsonify({"curriculum": filtered_curriculum}), 200


# # Function to clean extracted text
# def clean_text(raw_text):
#     """
#     Cleans the extracted OCR text by:
#     - Removing extra whitespace
#     - Removing special characters
#     - Fixing common OCR errors
#     """
#     import re

#     # Remove extra whitespace and line breaks
#     cleaned = re.sub(r"\s+", " ", raw_text)

#     # Remove special characters (retain alphanumerics and basic punctuation)
#     cleaned = re.sub(r"[^a-zA-Z0-9.,!?\'\";:()\\-]", " ", cleaned)

#     # Normalize spaces
#     cleaned = re.sub(r"\s+", " ", cleaned).strip()

#     return cleaned


# from openai import AsyncOpenAI

# async def evaluate_exam_script_with_groq(
#     extracted_text, relevant_text, image_url, language
# ):
#     try:
#         client = AsyncOpenAI(api_key=OPENAI_API_KEY)
#         all_responses = []
#         batch_size = 1  # Process 100 chunks at a time
#         total_chunks = len(extracted_text)

#         print(f"Total chunks: {total_chunks}, Processing in batches of {batch_size}.")

#         for i in range(0, total_chunks, batch_size):
#             batch = extracted_text[i : i + batch_size]  # Get 100 chunks
#             batch_text = "\n".join(batch)  # Combine into a single string

#             prompt = f"""
#             ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
#             *Return Analysis Of All Data In Exam Script Raw Data All Questions Evaluation DO NOT Cut Questions or Answers*                                                                                                                                       |
#             *Students Exam Script Raw Data :- {batch_text} This Needs To be converted into proper format before generating response and analysis generation. Extract all questions and their answers from Raw Data.*                                            |
#             ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________|

#             You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge.

#             After this, check every extracted question and properly analyze it with curriculum data. Respond in the format below:

#             STRICT REQUIREMENT: EXTRACT TEXT AND PROVIDE PROPER QUESTION FORMATTING AND ANSWERS

#             *Example Output*:
#             Exam Script Question 1  : [Extracted Question Text]
#             Correct Answer : [Correct Answer]
#             User's Answer : [User's Given Answer]

#             And so on, until all questions are processed. Ensure each question's correct answer has a justification.

#             After all, count all correct answers in the exam script and return the count like:
#             - Correct Answers: [count]
#             - Incorrect Answers: [count]
#             """

#             response = await client.chat.completions.create(
#                 model="gpt-4o",
#                 messages=[
#                     {
#                         "role": "system",
#                         "content": f"You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge {relevant_text}.",
#                     },
#                     {"role": "user", "content": prompt},
#                 ],
#                 stream=False,
#                 temperature=0.2,
#             )

#             # Extract response
#             evaluation_report = response.choices[0].message.content.strip()
#             all_responses.append(evaluation_report)

#         # Combine all batch responses
#         final_report = "\n\n".join(all_responses)

#         # Translate if language is Arabic
#         if language.lower() == "ar":
#             final_report = await translate(final_report, "ar")

#         return final_report

#     except Exception as e:
#         return f"Error during evaluation: {str(e)}"

from openai import AsyncOpenAI


async def evaluate_exam_script_with_groq(
    extracted_text, relevant_text, image_url, language
):
    try:
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)
        all_responses = []
        batch_size = 2000  # Process 100 chunks at a time
        total_chunks = len(extracted_text)

        print(f"Total chunks: {total_chunks}, Processing in batches of {batch_size}.")

        for i in range(0, total_chunks, batch_size):
            batch = extracted_text[i : i + batch_size]  # Get 100 chunks
            batch_text = "\n".join(batch)  # Combine into a single string

            prompt = f"""
            _____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            ****In Response Return All Questions Answer Dont provide placeholder i want evaluation for each question and answer.****
            ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            *Return Analysis Of All Data In Exam Script Raw Data All Questions Evaluation DO NOT Cut Questions or Answers*                                                                                                                                      |
            *Students Exam Script Raw Data :- {batch_text} This Needs To be converted into proper format before generating response and analysis generation. Extract all questions and their answers from Raw Data.*                                            |
            ____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________|

            You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge.

            After this, check every extracted question and properly analyze it with curriculum data. Respond in the format below:

            STRICT REQUIREMENT: EXTRACT TEXT AND PROVIDE PROPER QUESTION FORMATTING AND ANSWERS

            *Example Output*:
            Exam Script Question 1  : [Extracted Question Text]
            Correct Answer : [Correct Answer]
            User's Answer : [User's Given Answer]

            And so on, until all questions are processed. Ensure each question's correct answer has a justification.

            After all, count all correct answers in the exam script and return the count like:
            - Correct Answers: [count]
            - Incorrect Answers: [count]
            """

            response = await client.chat.completions.create(
                model="gpt-4.1-mini-2025-04-14",
                messages=[
                    {
                        "role": "system",
                        "content": f"You are an Exam Evaluator who evaluates user exam script text against curriculum knowledge {relevant_text}. If the batch text and the relevant text subject are not the same, explicitly state: 'Wrong curriculum.'",  # if batch text and relevant text:- subject are not same then say wrong curricluj
                    },
                    {"role": "user", "content": prompt},
                ],
                stream=False,
                temperature=0,
            )

            # Extract response
            evaluation_report = response.choices[0].message.content.strip()
            all_responses.append(evaluation_report)

        # Combine all batch responses
        final_report = "\n\n".join(all_responses)

        # Translate if language is Arabic
        if language.lower() == "ar":
            final_report = await translate(final_report, "ar")

        return final_report

    except Exception as e:
        return f"Error during evaluation: {str(e)}"


async def translate(text: str, target_language: str) -> str:
    """
    Asynchronously translates input text into the target language using OpenAI's GPT model.

    :param text: The text to be translated.
    :param target_language: The target language code (e.g., "ar" for Arabic, "fr" for French).
    :return: Translated text.
    """
    try:
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)

        response = await client.chat.completions.create(
            model="gpt-4.1-mini-2025-04-14",
            messages=[
                {
                    "role": "system",
                    "content": f"You are a professional translator. Translate the following text to {target_language} Ensure while tranlate dont change its meaning return direct translated text Also Translate all text into specified target langauge {target_language} each and every word.",
                },
                {"role": "user", "content": text},
            ],
            stream=False,
        )

        # Extract translated text
        translated_text = response.choices[0].message.content.strip()
        return translated_text

    except Exception as e:
        return f"Translation Error: {str(e)}"
