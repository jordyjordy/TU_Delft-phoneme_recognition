from random import randint

speakers = [
    ('f', 'y','S01'),
    ('f', 'o','S02'),
    ('m', 'o','S03'),
    ('f', 'y','S04'),
    ('f', 'o','S05'),
    ('m', 'y','S06'),
    ('f', 'o','S07'),
    ('f', 'y','S08'),
    # ('f', 'y','S09'),
    ('m', 'o','S10'),
    ('m', 'y','S11'),
    ('f', 'y','S12'),
    ('m', 'y','S13'),
    ('f', 'o','S14'),
    # ('m', 'y','S15'),
    # ('f', 'o','S16'),
    ('f', 'o','S17'),
    ('f', 'o','S18'),
    # ('m', 'o','S19'),
    ('f', 'o','S20'),
    ('f', 'y','S21'),
    ('m', 'o','S22'),
    ('m', 'o','S23'),
    ('m', 'o','S24'),
    ('f', 'o','S25'),
    # ('f', 'y','S26'),
    # ('f', 'o','S27'),
    ('m', 'y','S28'),
    ('m', 'o','S29'),
    # ('m', 'y','S30'),
    ('f', 'y','S31'),
    ('m', 'y','S32'),
    ('m', 'y','S33'),
    ('m', 'y','S34'),
    # ('m', 'o','S35'),
    ('m', 'o','S36'),
    ('f', 'y','S37'),
    ('m', 'o','S38'),
    ('f', 'y','S39'),
    ('m', 'y','S40') 
]

def extractspeakers(n):
    return speakers[n][2]

def extractagegender(n):
    return (speakers[n][1], speakers[n][0])
young = 0
old = 0
for speaker in speakers:
    if speaker[1] == 'o':
        old += 1
    else:
        young += 1


test = []
youngmale = 0
oldmale = 0
youngfemale = 0
oldfemale = 0
x = 0
while x < 1000 and len(test) < 4:
    val = randint(0, 31)
    if val in test:
        continue
    spk = speakers[val]
    if spk[1] == 'y' and spk[0] == 'm':
        if youngmale >= 1:
            continue
        youngmale+=1
    if spk[1] == 'o' and spk[0] == 'm':
        if oldmale >= 1: 
            continue
        oldmale+=1
    if spk[1] == 'y' and spk[0] == 'f':
        if youngfemale >= 1:
            continue
        youngfemale+=1
    if spk[1] == 'o' and spk[0] == 'f':
        if oldfemale >= 1:
            continue
        oldfemale+=1
    test.append(val)

male = 0
female = 0
young = 0
old = 0
while x < 1000 and len(test) < 6:
    val = randint(0,31)
    if val in test:
        continue
    spk = speakers[val]
    if spk[1] == 'y' and spk[0] == 'm':
        if young >= 1 or male >= 1:
            continue
        young += 1
        male += 1
    if spk[1] == 'o' and spk[0] == 'm':
        if old >= 1 or male >= 1: 
            continue
        old += 1
        male += 1
    if spk[1] == 'y' and spk[0] == 'f':
        if young >= 1 or female >= 1:
            continue
        young += 1
        female += 1
    if spk[1] == 'o' and spk[0] == 'f':
        if old >= 1 or female >= 1:
            continue
        old += 1
        female += 1
    test.append(val)

print(list(map(extractagegender,test)))
print(list(map(extractspeakers,test)))



