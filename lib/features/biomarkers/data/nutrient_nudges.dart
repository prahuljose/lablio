/// Concrete, general "levers" shown when a marker is high or low — diet and
/// lifestyle suggestions, not medical advice.
class NutrientNudge {
  final String? high;
  final String? low;
  const NutrientNudge({this.high, this.low});
}

const Map<String, NutrientNudge> kNutrientNudges = {
  'glucose': NutrientNudge(
      high: 'Cut refined carbs and sugary drinks, add fiber and protein to '
          'meals, and take a short walk after eating.'),
  'hba1c': NutrientNudge(
      high: 'Steady blood sugar with whole foods, regular movement and weight '
          'management; limit sugary drinks.'),
  'eag': NutrientNudge(
      high: 'Mirrors HbA1c — focus on steady blood sugar through diet and '
          'activity.'),
  'triglycerides': NutrientNudge(
      high: 'Reduce refined carbs, sugar and alcohol; add omega-3 fish and '
          'regular aerobic exercise.'),
  'hdl': NutrientNudge(
      low: 'Raise "good" cholesterol with aerobic exercise, healthy fats '
          '(olive oil, nuts, fish) and quitting smoking.'),
  'ldl': NutrientNudge(
      high: 'Cut saturated and trans fats, add soluble fiber (oats, beans) and '
          'exercise; discuss statins with a clinician if persistent.'),
  'non_hdl': NutrientNudge(
      high: 'Lower with less saturated fat, more fiber and exercise; track '
          'alongside ApoB.'),
  'apob': NutrientNudge(
      high: 'Reduce saturated fat and refined carbs, add fiber and omega-3 — a '
          'key target for cardiovascular risk.'),
  'total_cholesterol': NutrientNudge(
      high: 'Favor fiber and healthy fats with regular exercise; limit fried '
          'and processed foods.'),
  'crp': NutrientNudge(
      high: 'Lower inflammation with an anti-inflammatory diet, regular '
          'exercise, good sleep and treating any infection.'),
  'esr': NutrientNudge(
      high: 'Often reflects inflammation or infection — rest, hydrate and '
          'follow up if it stays elevated.'),
  'homocysteine': NutrientNudge(
      high: 'Usually responds to B-vitamins — folate, B12 and B6 from greens, '
          'legumes and fortified foods.'),
  'uric_acid': NutrientNudge(
      high: 'Cut alcohol (especially beer), high-fructose drinks and organ/red '
          'meats; stay well hydrated.'),
  'vitamin_d': NutrientNudge(
      low: 'Get 10–20 min of sunlight, eat fatty fish and eggs, and consider a '
          'vitamin D3 supplement.'),
  'vitamin_b12': NutrientNudge(
      low: 'Eat more meat, eggs and dairy; vegetarians and vegans often need a '
          'B12 supplement.'),
  'folate': NutrientNudge(
      low: 'Add leafy greens, legumes, citrus fruit and fortified grains.'),
  'ferritin': NutrientNudge(
      low: 'Pair iron-rich foods (red meat, lentils, spinach) with vitamin C '
          'to boost absorption.',
      high: 'May reflect inflammation or iron overload — limit iron and '
          'alcohol and follow up with a clinician.'),
  'serum_iron': NutrientNudge(
      low: 'Iron-rich foods plus vitamin C; avoid tea or coffee with '
          'iron-rich meals.'),
  'hemoglobin': NutrientNudge(
      low: 'Check iron, B12 and folate intake and treat the underlying cause '
          'of anemia.'),
  'magnesium': NutrientNudge(
      low: 'Add nuts, seeds, leafy greens, legumes and whole grains.'),
  'zinc': NutrientNudge(
      low: 'Add meat, shellfish, legumes, seeds and nuts.'),
  'alt': NutrientNudge(
      high: 'Support the liver: limit alcohol, lose excess weight and avoid '
          'unnecessary liver-stressing medications.'),
  'ast': NutrientNudge(
      high: 'Limit alcohol and manage weight; persistent elevation warrants a '
          'clinician review.'),
  'ggt': NutrientNudge(
      high: 'Strongly linked to alcohol and fatty liver — cut alcohol and '
          'refined carbs.'),
  'tsh': NutrientNudge(
      high: 'A high TSH suggests an underactive thyroid — discuss testing and '
          'treatment with a clinician.',
      low: 'A low TSH suggests an overactive thyroid — follow up with a '
          'clinician.'),
  'creatinine': NutrientNudge(
      high: 'Stay well hydrated and review protein intake and medications with '
          'a clinician.'),
};

/// The lever for a marker given its current status, or null if none applies.
String? nutrientNudgeFor(String biomarkerId,
    {required bool isHigh, required bool isLow}) {
  final n = kNutrientNudges[biomarkerId];
  if (n == null) return null;
  if (isHigh) return n.high;
  if (isLow) return n.low;
  return null;
}
