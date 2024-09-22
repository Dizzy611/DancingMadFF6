#include "customtrackselection.h"
#include "ui_customtrackselection.h"

CustomTrackSelection::CustomTrackSelection(QWidget *parent)
    : QDialog(parent)
    , ui(new Ui::CustomTrackSelection)
{
    ui->setupUi(this);
}

CustomTrackSelection::~CustomTrackSelection()
{
    delete ui;
}
