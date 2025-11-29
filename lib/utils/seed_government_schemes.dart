import 'package:cloud_firestore/cloud_firestore.dart';

class GovernmentSchemeSeeder {
  static Future<void> seedSchemes({bool forceReseed = false}) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('government_schemes');

    // Check if schemes already exist
    final existing = await collection.get();
    
    if (forceReseed && existing.docs.isNotEmpty) {
      print('Force reseeding: Deleting ${existing.docs.length} existing schemes...');
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      print('Deleted all existing schemes');
    } else if (existing.docs.length >= 10) {
      print('Government schemes already seeded (${existing.docs.length} found)');
      return;
    } else if (existing.docs.isNotEmpty && existing.docs.length < 10) {
      print('Found only ${existing.docs.length} schemes, deleting and reseeding...');
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
    }

    print('Seeding government schemes...');
    
    try {
      final List<Map<String, dynamic>> schemes = [
      // 1. Women - Beti Bachao Beti Padhao
      {
        'name': 'Beti Bachao, Beti Padhao',
        'subtitle': 'Save the Girl Child, Educate the Girl Child',
        'shortDescription':
            'A national campaign aimed at generating awareness and improving the efficiency of welfare services intended for girls.',
        'description':
            'Beti Bachao, Beti Padhao (BBBP) is a personal campaign of the Government of India that aims to generate awareness and improve the efficiency of welfare services intended for girls in India. The scheme was launched with an initial funding of ₹100 crore.\n\nThe scheme aims to address the declining Child Sex Ratio (CSR) and related issues of women empowerment over a life-cycle continuum. It is a tri-ministerial effort of Ministries of Women and Child Development, Health & Family Welfare and Education.\n\nThe objectives include preventing gender-biased sex selective elimination, ensuring survival and protection of the girl child, and ensuring education and participation of the girl child.',
        'requirements':
            '• Indian citizen\n• Family with girl child\n• Age of girl child: 0-10 years\n• Valid Aadhaar card of parents\n• Birth certificate of girl child\n• Bank account details\n• Residence proof',
        'benefits':
            '• Financial assistance for girl child education\n• Tax benefits under Section 80C\n• Partial withdrawal allowed for education at age 18\n• Full maturity amount at age 21\n• Insurance coverage for girl child\n• Low premium rates\n• Guaranteed returns',
        'category': 'Women',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Beti_Bachao%2C_Beti_Padhao_logo.svg/220px-Beti_Bachao%2C_Beti_Padhao_logo.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=800&q=80',
        'applyLink': 'https://wcd.nic.in/bbbp-schemes',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 2. Child - Integrated Child Development Services
      {
        'name': 'Integrated Child Development Services',
        'subtitle': 'ICDS - Nutrition & Health for Children',
        'shortDescription':
            'India\'s flagship programme providing food, preschool education, and primary healthcare to children under 6 years.',
        'description':
            'The Integrated Child Development Services (ICDS) Scheme is one of the flagship programmes of the Government of India and represents one of the world\'s largest and most unique programmes for early childhood care and development.\n\nIt is the foremost symbol of India\'s commitment to her children – India\'s response to the challenge of providing pre-school non-formal education on one hand and breaking the vicious cycle of malnutrition, morbidity, reduced learning capacity and mortality on the other.\n\nThe beneficiaries under the Scheme are children in the age group of 0-6 years, pregnant women and lactating mothers.',
        'requirements':
            '• Children aged 0-6 years\n• Pregnant women\n• Lactating mothers\n• Residence in ICDS operational area\n• Registration at local Anganwadi center\n• Aadhaar enrollment (if available)\n• No income criteria',
        'benefits':
            '• Supplementary nutrition\n• Immunization\n• Health check-ups\n• Referral services\n• Pre-school non-formal education\n• Nutrition and health education\n• Take-home rations for pregnant women',
        'category': 'Child',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/150px-Emblem_of_India.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800&q=80',
        'applyLink': 'https://icds-wcd.nic.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 3. Old Age - Indira Gandhi National Old Age Pension Scheme
      {
        'name': 'Indira Gandhi National Old Age Pension Scheme',
        'subtitle': 'IGNOAPS - Monthly Pension for Elderly',
        'shortDescription':
            'A non-contributory old age pension scheme for BPL elderly citizens providing monthly financial assistance.',
        'description':
            'The Indira Gandhi National Old Age Pension Scheme (IGNOAPS) is a non-contributory old age pension scheme that provides financial assistance to elderly people living below the poverty line.\n\nUnder this scheme, BPL persons aged 60 years or above are entitled to a monthly pension. The Central Government contribution is ₹200 per month for persons aged 60-79 years and ₹500 per month for persons aged 80 years and above.\n\nStates are encouraged to contribute an equal amount to ensure a meaningful pension to the elderly. Many states provide additional top-up over the central contribution.',
        'requirements':
            '• Age: 60 years or above\n• Below Poverty Line (BPL) family\n• Indian citizen\n• Valid Aadhaar card\n• Age proof certificate\n• BPL certificate/ration card\n• Bank account for DBT\n• Residence proof',
        'benefits':
            '• Monthly pension of ₹200 (60-79 years)\n• Monthly pension of ₹500 (80+ years)\n• Additional state contribution (varies by state)\n• Direct Bank Transfer\n• No contribution required\n• Lifelong benefit\n• Quarterly disbursement option available',
        'category': 'Old age',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/150px-Emblem_of_India.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1581579438747-104c53d7fbc4?w=800&q=80',
        'applyLink': 'https://nsap.nic.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 4. Health - Ayushman Bharat Pradhan Mantri Jan Arogya Yojana
      {
        'name': 'Ayushman Bharat PM-JAY',
        'subtitle': 'Pradhan Mantri Jan Arogya Yojana',
        'shortDescription':
            'World\'s largest health insurance scheme providing ₹5 lakh coverage per family per year for secondary and tertiary care.',
        'description':
            'Ayushman Bharat Pradhan Mantri Jan Arogya Yojana (AB PM-JAY) is a flagship scheme of Government of India that provides health coverage of ₹5 lakh per family per year for secondary and tertiary care hospitalization.\n\nIt is the world\'s largest health insurance/assurance scheme fully financed by the government. Over 10.74 crore poor and vulnerable families (approximately 50 crore beneficiaries) are entitled for these benefits.\n\nThe scheme provides cashless and paperless access to services at the point of service. There is no restriction on family size, age or gender. Pre-existing conditions are covered from day one.',
        'requirements':
            '• Families listed in SECC 2011 database\n• Valid Aadhaar card\n• Ration card/RSBY card\n• Any government ID proof\n• Mobile number for OTP verification\n• No income proof required\n• Auto-enrollment for eligible families',
        'benefits':
            '• Health coverage of ₹5 lakh per family per year\n• Cashless and paperless treatment\n• Coverage for 3 days pre-hospitalization\n• 15 days post-hospitalization expenses\n• 1,393 medical procedures covered\n• No cap on family size\n• Pre-existing diseases covered\n• Transportaion allowance',
        'category': 'Health',
        'logoUrl':
            'https://pmjay.gov.in/sites/default/files/2019-09/pmjay-logo.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=800&q=80',
        'applyLink': 'https://pmjay.gov.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 5. Education - PM POSHAN (Mid Day Meal Scheme)
      {
        'name': 'PM POSHAN Scheme',
        'subtitle': 'Pradhan Mantri Poshan Shakti Nirman (Mid Day Meal)',
        'shortDescription':
            'Providing hot cooked meals to school children to improve nutritional status and encourage school attendance.',
        'description':
            'PM POSHAN (formerly Mid Day Meal Scheme) is a centrally sponsored scheme which provides hot cooked meals to children in government and government-aided schools across India.\n\nThe scheme aims to address two of the pressing problems affecting most children in India, viz., hunger and education. It provides nutritious food to enhance enrollment, retention, and attendance while simultaneously improving nutritional levels among children.\n\nThe program reaches approximately 11.80 crore children across 11.20 lakh schools in India, making it one of the largest school feeding programs in the world.',
        'requirements':
            '• Students of government schools\n• Students of government-aided schools\n• Classes I to VIII (Primary & Upper Primary)\n• Enrolled in eligible school\n• Regular attendance\n• No income criteria\n• Special provisions for children with disabilities',
        'benefits':
            '• Free hot cooked meal every school day\n• Nutritious food with prescribed calories\n• 450 calories for primary students\n• 700 calories for upper primary students\n• 12g protein for primary, 20g for upper primary\n• Improved attendance rates\n• Better cognitive development\n• Supplementary nutrition for malnourished children',
        'category': 'Education',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/150px-Emblem_of_India.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=800&q=80',
        'applyLink': 'https://pmposhan.education.gov.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 6. Agriculture - PM-KISAN
      {
        'name': 'PM-KISAN Samman Nidhi',
        'subtitle': 'Pradhan Mantri Kisan Samman Nidhi',
        'shortDescription':
            'Income support of ₹6,000 per year in three equal installments to all landholding farmer families.',
        'description':
            'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN) is a Central Sector scheme with 100% funding from Government of India. It provides income support to all landholding farmers\' families in the country.\n\nUnder the scheme, an amount of ₹6000 per year is transferred in three equal installments of ₹2000 each directly into the bank accounts of eligible farmers under Direct Benefit Transfer mode.\n\nThe scheme was launched on 24th February 2019 by Prime Minister Shri Narendra Modi. As of now, more than 11 crore farmers have benefited from this scheme.',
        'requirements':
            '• Small and marginal farmers\n• Landholding farmer families\n• Valid Aadhaar card\n• Land records/documents\n• Bank account linked to Aadhaar\n• Not an income tax payee\n• Not a government employee\n• Mobile number for updates',
        'benefits':
            '• ₹6,000 per year income support\n• Three installments of ₹2,000 each\n• Direct Bank Transfer (DBT)\n• No middlemen involved\n• Covers all landholding farmers\n• Immediate benefit on registration\n• Life certificate not required\n• E-KYC through mobile app',
        'category': 'Agriculture',
        'logoUrl':
            'https://pmkisan.gov.in/Images/pmkisan_image.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=800&q=80',
        'applyLink': 'https://pmkisan.gov.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 7. Employment - MGNREGA
      {
        'name': 'MGNREGA',
        'subtitle': 'Mahatma Gandhi National Rural Employment Guarantee Act',
        'shortDescription':
            'Guarantees 100 days of wage employment per year to every rural household whose adult members volunteer for unskilled manual work.',
        'description':
            'The Mahatma Gandhi National Rural Employment Guarantee Act (MGNREGA) is an Indian labour law and social security measure that aims to guarantee the "right to work".\n\nIt provides at least 100 days of guaranteed wage employment in a financial year to every rural household whose adult members volunteer to do unskilled manual work. The wages are paid within 15 days of work completion.\n\nThe act was first proposed in 1991. After intense debate, it was finally accepted by the government and enacted on August 25, 2005. It is one of the largest and most ambitious social security and public works programs in the world.',
        'requirements':
            '• Adult members of rural household\n• Willing to do unskilled manual work\n• Job card registration\n• Valid Aadhaar card\n• Bank/Post office account\n• Application for work in written\n• Local Gram Panchayat registration\n• Residence in rural area',
        'benefits':
            '• 100 days guaranteed employment per year\n• Wages as per state minimum wage\n• Unemployment allowance if work not provided\n• Work within 5 km of residence\n• Wages within 15 days\n• One-third reservation for women\n• Worksite facilities (drinking water, shade, creche)\n• Compensation for injury',
        'category': 'Employment',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/150px-Emblem_of_India.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=800&q=80',
        'applyLink': 'https://nrega.nic.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 8. Women - Pradhan Mantri Matru Vandana Yojana
      {
        'name': 'Pradhan Mantri Matru Vandana Yojana',
        'subtitle': 'PMMVY - Maternity Benefit Programme',
        'shortDescription':
            'Cash incentive of ₹5,000 for pregnant women and lactating mothers for first living child.',
        'description':
            'Pradhan Mantri Matru Vandana Yojana (PMMVY) is a maternity benefit programme being implemented in all districts of India. It provides partial compensation for wage loss during pregnancy and childbirth.\n\nUnder PMMVY, pregnant women and lactating mothers receive ₹5,000 in three installments for the first living child, subject to fulfilling specific conditions relating to maternal and child health.\n\nThe remaining cash incentive is given under Janani Suraksha Yojana (JSY) after institutional delivery so that on an average, a woman gets ₹6,000.',
        'requirements':
            '• Pregnant women and lactating mothers\n• First living child only\n• Age 19 years and above\n• Not employed in government/PSU\n• Registration within 150 days of pregnancy\n• Aadhaar card\n• Bank account\n• MCP card (Mother and Child Protection)',
        'benefits':
            '• First installment: ₹1,000 on early registration\n• Second installment: ₹2,000 after 6 months of pregnancy\n• Third installment: ₹2,000 after child birth registration\n• Additional ₹1,000 under JSY for institutional delivery\n• Total benefit: ₹6,000\n• Direct bank transfer\n• Promotes institutional delivery',
        'category': 'Women',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/150px-Emblem_of_India.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=800&q=80',
        'applyLink': 'https://pmmvy.wcd.gov.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 9. Education - National Scholarship Portal
      {
        'name': 'National Scholarship Portal',
        'subtitle': 'NSP - One Stop Solution for Scholarships',
        'shortDescription':
            'Unified platform providing various central and state government scholarships to students from Class 1 to PhD.',
        'description':
            'The National Scholarship Portal (NSP) is a one-stop solution for end-to-end scholarship processes right from submission of student application, verification, sanction and disbursal to end beneficiary.\n\nNSP brings together Central Government Scholarships, State Government Scholarships, and UGC/AICTE Schemes on a single platform. Students can search and apply for various scholarships offered by the Government of India.\n\nThe portal has streamlined the scholarship process, reduced delays, and ensured transparency through Direct Benefit Transfer.',
        'requirements':
            '• Indian citizen\n• Enrolled in recognized institution\n• Meeting specific scholarship criteria\n• Family income as per scheme limits\n• Valid Aadhaar card\n• Bank account linked with Aadhaar\n• Previous year marksheet\n• Caste/community certificate (if applicable)',
        'benefits':
            '• Pre-Matric scholarships (Class 1-10)\n• Post-Matric scholarships (Class 11-12)\n• Top Class Education scholarships\n• Merit-cum-Means scholarships\n• Central Sector Scheme scholarships\n• Minority community scholarships\n• Scholarships for SC/ST/OBC students\n• Direct benefit transfer to bank account',
        'category': 'Education',
        'logoUrl':
            'https://scholarships.gov.in/public/assets/images/NSP-logo-2024.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80',
        'applyLink': 'https://scholarships.gov.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 10. Health - Pradhan Mantri Surakshit Matritva Abhiyan
      {
        'name': 'Pradhan Mantri Surakshit Matritva Abhiyan',
        'subtitle': 'PMSMA - Safe Motherhood Campaign',
        'shortDescription':
            'Free antenatal care on 9th of every month for pregnant women to ensure safe pregnancy and healthy baby.',
        'description':
            'Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA) is a programme launched by the Ministry of Health and Family Welfare, Government of India. It provides fixed-day assured, comprehensive and quality antenatal care universally to all pregnant women on the 9th of every month.\n\nThe program aims to provide assured, comprehensive and quality antenatal care to all pregnant women visiting government health facilities on a designated day. OBGYNs/Physicians from the private sector also volunteer to provide services.\n\nPMSMA guarantees a minimum package of antenatal care services to pregnant women in their 2nd/3rd trimesters at designated government health facilities.',
        'requirements':
            '• Pregnant women in 2nd/3rd trimester\n• Visit government health facility on 9th of month\n• Mother and Child Protection (MCP) card\n• Aadhaar card (if available)\n• Previous check-up records\n• No income criteria\n• Open to all pregnant women\n• Registration at local health center',
        'benefits':
            '• Free comprehensive antenatal check-up\n• Blood pressure monitoring\n• Hemoglobin test\n• Blood sugar test\n• Urine test for protein/sugar\n• Ultrasound (if required)\n• Identification of high-risk pregnancies\n• Appropriate referral and follow-up\n• Iron and calcium supplementation',
        'category': 'Health',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/150px-Emblem_of_India.svg.png',
        'imageUrl':
            'https://images.unsplash.com/photo-1584515933487-779824d29309?w=800&q=80',
        'applyLink': 'https://pmsma.nhp.gov.in/',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    // Add all schemes to Firestore
    for (final scheme in schemes) {
      await collection.add(scheme);
      print('Added scheme: ${scheme['name']}');
    }

    print('Successfully seeded ${schemes.length} government schemes!');
    } catch (e) {
      print('Error seeding government schemes: $e');
    }
  }
}
