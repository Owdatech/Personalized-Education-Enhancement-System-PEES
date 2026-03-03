import os
from teachingplans import retrieve_relevant_text1
from openai import AsyncOpenAI
import asyncio

client = AsyncOpenAI(
    api_key=os.getenv('OPENAI_API_KEY', '')
)


async def GetLangugage(curriculum_id):

    query1 = f"""
Generate a high-level summary of the curriculum coverage , **subject name**. 
The summary should concisely capture the key themes, core concepts, and essential learning objectives covered in these topics. 
Ensure clarity, coherence, and relevance while avoiding unnecessary details or extraneous information.

"""
    relevant_text = await retrieve_relevant_text1(curriculum_id, query1)
    # print(relevant_text)

    prompt = f"""
        Your task to provide me the langugae only from the:- {relevant_text}
    
    """

    try:
        completion = await client.chat.completions.create(
            model="chatgpt-4o-latest",
            messages=[{"role": "user", "content": prompt}],
            temperature=0,
        )

        print(completion.choices[0].message.content)
        return completion.choices[0].message.content
    except Exception as e:
        print(f"Error communicating with OpenAI API: {e}")
        return "An error occurred during the evaluation process."


# GetLangugage


# async def main():
#     # pdf_path = "handwritten.png"
#     # pdf_path = "Science grade 5-page-00003.jpeg"
#     # pdf_path = "arabicFile.jpeg"
#     result = await GetLangugage("Hi4J62o2ZBcOz5aONvOX")

#     if result:
#         print(result)
#     else:
#         print("Extraction failed.")

# # Run this to avoid `asyncio.run()` issues in an active event loop
# if __name__ == "__main__":
#     asyncio.run(main())
