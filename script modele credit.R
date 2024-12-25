# Charger les bibliothèques nécessaires
install.packages(c("dplyr", "ggplot2", "margins"))

library(dplyr)
library(ggplot2)
library(MASS)  # Pour les modèles logistiques
library(margins)  # Pour calculer les effets marginaux

#Chargement des données 
# Liste variables :

credit<- read.csv("German_creditDV.csv")

# Voir les premières lignes des données
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

# Résumer les effets marginaux
summary(marginal_effects)

# Calcul des Odds Ratios (exponentiation des coefficients)
odds_ratios <- exp(coef(model_logit))
odds_ratios


# Diviser les données en jeu d'entraînement et jeu de test
n <- nrow(credit)
train_index <- sample(1:n, size = 0.7 * n)  # 70% des données pour l'entraînement
train_data <- credit[train_index, ]
test_data <- credit[-train_index, ]

# Ajuster un modèle logistique (régression logistique) sur les données d'entraînement
model_logit <- glm(credit_risk ~ age + amount + duration + number_credits  ,   data = train_data, family = binomial())
# Résumé du modèle
summary(model_logit)

# Prédictions pour le jeu d'entraînement
train_predictions <- predict(model_logit, newdata = train_data, type = "response")

# Prédictions pour le jeu de test
test_predictions <- predict(model_logit, newdata = test_data, type = "response")

# Définir le seuil de classification (0.5)
threshold <- 0.5

# Convertir les probabilités en classes (0 ou 1)
train_predictions_class <- ifelse(train_predictions > threshold, 1, 0)
test_predictions_class <- ifelse(test_predictions > threshold, 1, 0)

# Comparer les classes prédites avec les valeurs observées
train_accuracy <- mean(train_predictions_class == train_data$credit_risk)
test_accuracy <- mean(test_predictions_class == test_data$credit_risk)

# Afficher les pourcentages de réussite
cat("Pourcentage de prédiction correcte sur le jeu d'entraînement : ", train_accuracy * 100, "%\n")
cat("Pourcentage de prédiction correcte sur le jeu de test : ", test_accuracy * 100, "%\n")


# Comparer les classes prédites avec les valeurs réelles pour l'entraînement
train_confusion_matrix <- table(Predicted = train_predictions_class, Actual = train_data$credit_risk)

# Comparer les classes prédites avec les valeurs réelles pour le test
test_confusion_matrix <- table(Predicted = test_predictions_class, Actual = test_data$credit_risk)

# Afficher les matrices de confusion
cat("Matrice de confusion pour le jeu d'entraînement :\n")
print(train_confusion_matrix)


cat("\nMatrice de confusion pour le jeu de test :\n")
print(test_confusion_matrix)
