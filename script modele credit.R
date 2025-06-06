# Charger les biblioth�ques n�cessaires
install.packages(c("dplyr", "ggplot2", "margins"))

library(dplyr)
library(ggplot2)
library(MASS)  # Pour les mod�les logistiques
library(margins)  # Pour calculer les effets marginaux

#Chargement des donn�es 
# Liste variables :

credit<- read.csv("German_creditDV.csv")

# Voir les premi�res lignes des donn�es
head(credit)

#Nombre de lignes et de colonnes
dim(credit)

# Statistiques descriptives
summary(credit)
summary(credit[, c("age", "amount", "duration", "number_credits")])

# Afficher les types de variables
str(credit )

#modele (logit)
model_logit <- glm(credit_risk ~ age + amount + duration + number_credits,   data = credit, family = binomial())
summary(model_logit)     
# Calculer les effets marginaux
marginal_effects <- margins(model_logit)

# R�sumer les effets marginaux
summary(marginal_effects)

# Calcul des Odds Ratios (exponentiation des coefficients)
odds_ratios <- exp(coef(model_logit))
odds_ratios


# Diviser les donn�es en jeu d'entra�nement et jeu de test
n <- nrow(credit)
train_index <- sample(1:n, size = 0.7 * n)  # 70% des donn�es pour l'entra�nement
train_data <- credit[train_index, ]
test_data <- credit[-train_index, ]

# Ajuster un mod�le logistique (r�gression logistique) sur les donn�es d'entra�nement
model_logit <- glm(credit_risk ~ age + amount + duration + number_credits  ,   data = train_data, family = binomial())
# R�sum� du mod�le
summary(model_logit)

# Pr�dictions pour le jeu d'entra�nement
train_predictions <- predict(model_logit, newdata = train_data, type = "response")

# Pr�dictions pour le jeu de test
test_predictions <- predict(model_logit, newdata = test_data, type = "response")

# D�finir le seuil de classification (0.5)
threshold <- 0.5

# Convertir les probabilit�s en classes (0 ou 1)
train_predictions_class <- ifelse(train_predictions > threshold, 1, 0)
test_predictions_class <- ifelse(test_predictions > threshold, 1, 0)

# Comparer les classes pr�dites avec les valeurs observ�es
train_accuracy <- mean(train_predictions_class == train_data$credit_risk)
test_accuracy <- mean(test_predictions_class == test_data$credit_risk)

# Afficher les pourcentages de r�ussite
cat("Pourcentage de pr�diction correcte sur le jeu d'entra�nement : ", train_accuracy * 100, "%\n")
cat("Pourcentage de pr�diction correcte sur le jeu de test : ", test_accuracy * 100, "%\n")


# Comparer les classes pr�dites avec les valeurs r�elles pour l'entra�nement
train_confusion_matrix <- table(Predicted = train_predictions_class, Actual = train_data$credit_risk)

# Comparer les classes pr�dites avec les valeurs r�elles pour le test
test_confusion_matrix <- table(Predicted = test_predictions_class, Actual = test_data$credit_risk)

# Afficher les matrices de confusion
cat("Matrice de confusion pour le jeu d'entra�nement :\n")
print(train_confusion_matrix)


cat("\nMatrice de confusion pour le jeu de test :\n")
print(test_confusion_matrix)
