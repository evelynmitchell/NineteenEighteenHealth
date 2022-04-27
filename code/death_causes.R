#death_causes.R
#ajaantoine
#1dec2021

# classify causes of death

library(tidyverse)

causes_raw <- "data/death_causes_to_categorize.csv" %>%
  read_csv()

tb_list <- 
  c("Other forms of tuberculosis",
    "Tuberculosis (all forms)", 
    "Tuberculosis (other forms)",
    "Tuberculosis of lungs", 
    "Tuberculosis of respiratory system", 
    "Tuberculosis of respiratory system, etc.*", 
    "Tuberculosis of the lungs",
    "Tuberculosis of the meninges, etc",
    "Tuberculosis of the respiratory system",
    "Tuberculosis, all forms", 
    "Tuberculous meningitis")

flu_pneumonia_list <-
  c("Influenza",
    "Influenza and pneumonia (all forms)",
    "Influenza and pneumonia except pneumonia of newborn",
    "Influenza and pneumonia, except pneumonia of newborn",
    "Pneumonia", 
    "Pneumonia (all forms)",
    "Pneumonia (all forms) and influenza",
    "Pneumonia (lobar and unqualified)")

# these are to avoid double counting
total_list <-
  c("Total", 
    "Total deaths",
    "All causes")

# avoid double counting in 1949-1950
cardio_double_list <- 
  c("Diseases of cardiovascular system",
    "Vascular lesions affecting central nervous system",
    "Rheumatic fever",
    "Diseases of heart",
    "Hypertension without mention of heart and general arteriosclerosis",
    "Other diseases of circulatory system",
    "Chronic and unspecified nephritis and other renal sclerosis")

# Infectious List (12/31/21)
# 1) added Meningitis, except meningococoal and tuberculosis 

inf_list <-
  c("Acute poliomyelitis",
    "Acute nephritis and Bright's disease", 
    "Acute nephritis and nephritis with edema, including nephrosis",
    "All other epidemic diseases",
    "All other infective and parasitic diseases", 
    "Appendicitis and typhlitis",
    "Bronchitis",
    "Cerebrospinal (meningococcus) meningitis",
    "Diarrhea and enteritis (under 2 years)", 
    "Diarrhea and enteritis: 2 years and over",
    "DIARRHEA AND ENTERITIS: 2 years and over",
    "Diarrhea and enteritis: under 2 years", 
    "Diarrhea and enteritis: Under 2 years", 
    "DIARRHEA AND ENTERITIS: Under 2 years", 
    "Diarrhea, enteritis and ulceration of intestines", 
    "Diarrhea, enteritis, and ulceration of intestines", 
    "Diarrhea, enteritis, and ulceration of intestines (under 2 years)",
    "Diphtheria",
    "Diphtheria and croup",
    "Dysentery",
    "Dysentery, all forms", 
    "Epidemic cerebrospinal meningitis", 
    "Erysipelas", 
    "Exophthalmic goiter",
    "Gastritis, duodenitis, enteritis, and colitis, except diarrhea of newborn",
    "Malaria", 
    "Malarial fever", 
    "Measles", 
    "Meningitis", 
    "Meningitis, except meningococal and tuberculosis",
    "Meningococal infections",
    "Meningococcus meningitis", 
    "Nephritis",
    "Nephritis, Bright's disease",
    "Other diseases of digestive system",
    "Other epidemic diseases",
    "Poliomyelitis, polioencephalitis (acute)",
    "Puerperal fever", 
    "Puerperal septicemia", 
    "Scarlet fever",
    "Smallpox",
    "Syphilis",
    "Syphilis and its sequelae",
    "Typhoid and para-typhoid fever",
    "Typhoid and paratyphoid fever",
    "Typhoid fever",
    "Whooping cough")

# Non Infectious List (12/31/21)
# 1) added Biliary calculi, other diseases of gall bladder 

non_inf_list <-
  c("Accident",
    "Accidental and unspecified external causes",
    "Acute rheumatic fever", 
    "Alcoholism (ethylism)",
    "All other accidents",
    "Appendicitis",
    "Automobile accidents",
    "Automobile accidents: Collision with trains and street cars",
    "Automobile accidents: In collision with--Railroad trains",
    "Automobile accidents: In collision with--Street cars",
    "Automobile accidents: In collision with railroad trains and street cars",
    "AUTOMOBILE ACCIDENTS: In collision with railroad trains and street cars",
    "Automobile accidents: Primary",
    "AUTOMOBILE ACCIDENTS: Primary",
    "Biliary calculi, other diseases of gall bladder",
    "Bright's disease and nephritis", 
    "Cancer",
    "Cancer and other malignant tumors",
    "Cancers and other malignant tumors", 
    "Cerebral hemorrhage and softening",
    "Cerebral hemorrhage, embolism, thrombosis",
    "Childbirth", 
    "Chronic and unspecified nephritis and other renal sclerosis",
    "Chronic rheumatic diseases of heart",
    "Chronic rheumatism, osteoarthritis",
    "Cirrhosis of liver",
    "Cirrhosis of the liver",
    "Congenital debility and malformations",
    "Congenital malformations",
    "Congenital malformations and diseases of early infancy",
    "Congenital malformations and diseases peculiar to the first year",
    "Congenital malformations and diseases peculiar to the first year (except premature birth)",
    "Congential malformations and diseases of early infancy", 
    "Deliveries and complications of pregnancy, childbirth, and the puerperium",
    "Diabetes",
    "Diabetes mellitus",
    "Diseases of cardiovascular system", 
    "Diseases of circulatory system", 
    "Diseases of coronary arteries, angina pectoris", 
    "Diseases of ear, nose, and throat", 
    "Diseases of early infancy",
    "Diseases of heart", 
    "Diseases of heart (other forms)", 
    "Diseases of pregnancy, childbirth, and the puerperium", 
    "Diseases of the heart", 
    "Early infancy",
    "Hernia, intestinal obstruction", 
    "Homicide", 
    "Hypertension without mention of heart and general arteriosclerosis", 
    "Intracranial lesions of vascular origin", 
    "Major cardiovascular renal diseases", 
    "Malignant neoplasma, including neoplasma of lymphatic and hematopoietic tissues",
    "Motor vehicle accidents",
    "Motor vehicle accidents: Automobile accidents (primary)",
    "Motor vehicle accidents: Other motor vehicle accidents",
    "Organic diseases of the heart",
    "Other [organic] diseases of the heart",
    "Other accidents",
    "Other diseases of circulatory system",
    "Other diseases of digestive system", 
    "Other diseases of nervous system", 
    "Other diseases of respiratory system",
    "Other diseases peculiar to early infancy",
    "Other diseases, respiratory system",
    "Other puerperal causes",
    "Other puerperal affections",
    "Other respiratory diseases",
    "Other violence", 
    "Pellagra (except alcoholic)", 
    "Premature birth", 
    "Rheumatic fever", 
    "Rheumatism",
    "Rheumatism and gout",
    "Suicide",
    "Tumor",
    "Ulcer of stomach and duodenum",
    "Ulcer of stomach or duodenum",
    "Vascular lesions affecting central nervous system",
    "Violent deaths (excluding suicide)",
    "Violent deaths (suicide excepted)")

other_list <- c("All other causes",
                "All other causes*",
                "All other defined causes")

unknown_list <- 
  c("Cause unknown",
    "Ill-defined and unknown",
    "Ill-defined and unknown causes",
    "Ill-definited causes",
    "Other external causes",
    "Senility, ill-defined and unknown causes",
    "Symptoms, senility, and ill-defined conditions",
    "Unknown and illdefined diseases",
    "Unknown or ill-defined diseases")

# Kid_list notes: (12/3/21) 
# 1) added set of congenital causes because we think these will almost all be deaths during or 
# shortly after birth, and added premature birth. (I went back and forth on this because if 
# they truly were congenital, you'd expect them to be affected by different things than, say, 
# diphtheria. But ultimately we already know that where public health interventions 
# mattered most was for infants, so I'm thinking this is where we might see some action. ewf)
# 2) removed pellagra as a childhood disease. See: https://ajph.aphapublications.org/doi/pdfplus/10.2105/AJPH.90.5.727

kid_list <-
  c("Whooping cough",
    "Diphtheria",
    "Diphtheria and croup",
    "Diarrhea and enteritis (under 2 years)",
    "Diarrhea and enteritis: under 2 years",
    "Diarrhea and enteritis: Under 2 years",
    "DIARRHEA AND ENTERITIS: Under 2 years",
    "Diarrhea, enteritis, and ulceration of intestines (under 2 years)",
    "Congenital malformations and diseases of early infancy", 
    "Congenital malformations and diseases peculiar to the first year (except premature birth)",
    "Premature birth",
    "Diseases of early infancy",
    "Early infancy",
    "Other diseases peculiar to early infancy",
    "Measles",
    "Acute poliomyelitis",
    "Poliomyelitis, polioencephalitis (acute)",
    "Scarlet fever")

# Water_list notes: (12/21/21) 
# Cholera, Glanders, Hookwoorm, and Intestinal parasites are not in the list of causes. 
# glanders and hookworm are ambiguous. Appendicitis is not always waterborne but can be and 
# is so easily confused with waterborne illness that I think it makes sense to include; same
# reasoning for "other digestive" (which is also included to minimize distortion from what clearly 
# waterborne specific causes are or aren't included in each ICD). We'll include a note on this if 
# waterborne as a category seems to matter, and/or can try again without those ones. But since this 
# is a smaller set of deaths than TB and flu, I thought it made sense to be expansive.

water_list <- 
  c("Typhoid and para-typhoid fever",
    "Typhoid and paratyphoid fever",
    "Typhoid fever",
    "Dysentery",
    "Dysentery, all forms",
    "Acute poliomyelitis",
    "Poliomyelitis, polioencephalitis (acute)",
    "Diarrhea and enteritis (under 2 years)",
    "Diarrhea and enteritis: 2 years and over",
    "DIARRHEA AND ENTERITIS: 2 years and over",
    "Diarrhea and enteritis: under 2 years",
    "Diarrhea and enteritis: Under 2 years",
    "DIARRHEA AND ENTERITIS: Under 2 years",
    "Diarrhea, enteritis and ulceration of intestines",
    "Diarrhea, enteritis, and ulceration of intestines",
    "Diarrhea, enteritis, and ulceration of intestines (under 2 years)",
    "Appendicitis",
    "Appendicitis and typhlitis",
    "Other diseases of digestive system",
    "Gastritis, duodenitis, enteritis, and colitis, except diarrhea of newborn")


# additional causes added by LHV: (1/11/22)  
# 1. measles
measles_list <-
  c("Measles")

# 2. whooping cough
whooping_cough_list <-
  c("Whooping cough")

# 3. diphtheria
diphtheria_list <-
  c("Diphtheria",
    "Diphtheria and croup")

# 4. malaria
malaria_list <-
  c("Malaria", 
    "Malarial fever")

# 5. puerperal
puerperal_list <- 
  c("Puerperal fever", 
  "Puerperal septicemia")

 # 6. bronchitis
bronchitis_list <- 
  c("Bronchitis")

# 7. scarlet fever
scarlet_fever_list <-
  c("Scarlet fever")

# 8. syphilis
syphilis_list <-
  c("Syphilis",
    "Syphilis and its sequelae")



causes_out <- causes_raw %>%
  mutate(total = (cause %in% total_list)) %>%
  mutate(tb = (cause %in% tb_list)) %>%
  mutate(flu_pneumonia = (cause %in% flu_pneumonia_list)) %>%
  # infectious should be all infectious stuff above PLUS flu and tb
  mutate(inf = (cause %in% c(inf_list, tb_list, flu_pneumonia_list))) %>%
  mutate(non_inf = (cause %in% non_inf_list)) %>%
  mutate(unknown = (cause %in% unknown_list)) %>%
  mutate(other = (cause %in% other_list)) %>%
  mutate(kid = (cause %in% kid_list)) %>%
  mutate(cardio_double = (cause %in% cardio_double_list)) %>%
  mutate(water = (cause %in% water_list)) %>%
  mutate(measles = (cause %in% measles_list)) %>% 
  mutate(whooping_cough = (cause %in% whooping_cough_list)) %>% 
  mutate(diphtheria = (cause %in% diphtheria_list)) %>% 
  mutate(malaria = (cause %in% malaria_list)) %>% 
  mutate(puerperal = (cause %in% puerperal_list)) %>% 
  mutate(bronchitis = (cause %in% bronchitis_list)) %>% 
  mutate(scarlet_fever = (cause %in% scarlet_fever_list)) %>% 
  mutate(syphilis = (cause %in% syphilis_list))  
 
# view(causes_out)

causes_out %>%
  select(cause, total, tb, flu_pneumonia, inf, non_inf, unknown, other, cardio_double, 
         kid, water, measles, whooping_cough, diphtheria, malaria, puerperal, bronchitis, scarlet_fever, syphilis) %>%
  write_csv(file = "data/death_causes_out.csv")

