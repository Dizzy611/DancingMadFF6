#ifndef CUSTOMTRACKSELECTION_H
#define CUSTOMTRACKSELECTION_H

#include <QDialog>

namespace Ui {
class CustomTrackSelection;
}

class CustomTrackSelection : public QDialog
{
    Q_OBJECT

public:
    explicit CustomTrackSelection(QWidget *parent = nullptr);
    ~CustomTrackSelection();

private:
    Ui::CustomTrackSelection *ui;
};

#endif // CUSTOMTRACKSELECTION_H
